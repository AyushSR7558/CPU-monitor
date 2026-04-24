#!/usr/bin/env bash
# =========================
# CPU MONITOR (B/W ASCII)
# =========================
declare -A curr_data=()
declare -A prev_data=()
declare -i NUM_CPUS=0

# ── Cleanup ───────────────────────────────────────────────────────────────────
cleanup() {
	printf "\033[?25h"       # show cursor
	printf "\033[?1049l"     # leave alternate screen
	tput cnorm 2>/dev/null
	exit 0
}
trap cleanup INT TERM EXIT

# ── Data helpers ──────────────────────────────────────────────────────────────
copy_data() {
	prev_data=()
	for key in "${!curr_data[@]}"; do
		prev_data[$key]="${curr_data[$key]}"
	done
}

read_proc() {
	curr_data=()
	local key user nice system idle iowait irq softirq steal guest guest_nice
	while read -r key user nice system idle iowait \
		irq softirq steal guest guest_nice; do
		[[ $key != cpu* ]] && continue
		[[ $key == "cpu" ]]  && continue
		local busy=$(( user + nice + system + irq + softirq + steal + guest + guest_nice ))
		local idle_total=$(( idle + iowait ))
		curr_data[$key]="$busy $idle_total"
	done < /proc/stat
	NUM_CPUS=${#curr_data[@]}
}

# ── Draw one bar IN PLACE (row already positioned by caller) ──────────────────
print_bar() {
	local key=$1
	local busy1 idle1 busy2 idle2
	read -r busy1 idle1 <<< "${prev_data[$key]}"
	read -r busy2 idle2 <<< "${curr_data[$key]}"
	local busy=$(( busy2 - busy1 ))
	local idle=$(( idle2 - idle1 ))
	local total=$(( busy + idle ))
	local usage=0
	(( total > 0 )) && usage=$(( 1000 * busy / total ))
	local int=$(( usage / 10 ))
	local frac=$(( usage % 10 ))
	local length=40
	local num_bars=$(( usage * length / 1000 ))
	local bar=""
	for ((i=0;        i<num_bars; i++)); do bar+='#'; done
	for ((i=num_bars; i<length;   i++)); do bar+='.'; done
	# \033[2K = erase entire current line, then write fresh content
	printf "\033[2K %-6s [%s] %3d.%d%%\n" "$key" "$bar" "$int" "$frac"
}

# ── Draw static header ONCE ───────────────────────────────────────────────────
draw_header() {
	printf "\033[H"          # cursor to top-left
	printf "\033[2K==============================================\n"
	printf "\033[2K             CPU USAGE MONITOR\n"
	printf "\033[2K==============================================\n"
	printf "\033[2K\n"
}

# ── Update only the bar rows each tick ───────────────────────────────────────
create_visual() {
	# Header is static — just reposition past it (4 lines)
	printf "\033[5;1H"       # move to row 5, col 1 (below 4-line header)

	for key in $(printf "%s\n" "${!curr_data[@]}" | sort -V); do
		print_bar "$key"
	done

	# Footer — rewrite in place
	printf "\033[2K\n"
	printf "\033[2KPress Ctrl+C to exit\n"
}

# ── Entry point ───────────────────────────────────────────────────────────────
main() {
	printf "\033[?1049h"     # enter alternate screen
	printf "\033[?25l"       # hide cursor
	tput civis 2>/dev/null

	# Draw the full screen once (header + empty bars)
	read_proc
	printf "\033[H\033[J"    # clear only on first paint
	draw_header
	sleep 1

	while true; do
		copy_data
		read_proc
		draw_header          # rewrites header lines in-place (no clear)
		create_visual        # rewrites bar lines in-place (no clear)
		sleep 1
	done
}

main
