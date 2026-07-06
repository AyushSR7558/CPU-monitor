# CPU Usage Monitor

A lightweight real-time CPU usage monitoring tool written entirely in Bash.

The script reads CPU statistics directly from Linux's `/proc/stat` file, calculates the CPU utilization of each logical CPU core, and displays the results as continuously updating ASCII progress bars in the terminal.

No external monitoring tools or third-party dependencies are required.

## Features

- Real-time per-CPU-core usage monitoring.
- Reads CPU statistics directly from `/proc/stat`.
- Displays CPU utilization using ASCII progress bars.
- Shows CPU usage with one decimal place of precision.
- Automatically detects the number of logical CPU cores.
- Sorts CPU cores numerically (`cpu0`, `cpu1`, `cpu2`, ...).
- Updates CPU statistics every second.
- Uses the terminal alternate screen buffer.
- Updates terminal lines in place to reduce screen flickering.
- Hides the cursor while the monitor is running.
- Restores the terminal state when the program exits.
- Supports exiting safely with `Ctrl+C`.
- Requires no third-party libraries.

## Requirements

- Linux operating system.
- Bash 4 or later.
- Access to `/proc/stat`.
- A terminal that supports ANSI escape sequences.
- `tput` is optional and is used as an additional method for controlling cursor visibility.

## Installation

Clone the repository:

```bash
git clone <repository-url>
cd <repository-directory>
```

Make the script executable:

```bash
chmod +x cpu-monitor.sh
```

## Usage

Run the script:

```bash
./cpu-monitor.sh
```

You can also run the script explicitly using Bash:

```bash
bash cpu-monitor.sh
```

Press `Ctrl+C` to stop the monitor.

## Example Output

```text
==============================================
             CPU USAGE MONITOR
==============================================

cpu0   [############............................] 30.5%
cpu1   [####################....................] 50.2%
cpu2   [########................................] 20.1%
cpu3   [################################........] 80.4%

Press Ctrl+C to exit
```

## How It Works

Linux exposes CPU statistics through the `/proc/stat` virtual file.

Example:

```text
cpu  12093 42 3982 98172 721 0 312 0 0 0
cpu0 3021 12 1002 24512 182 0 80 0 0 0
cpu1 2998 10 987 24610 175 0 79 0 0 0
```

Each CPU line contains cumulative amounts of time spent in different CPU states:

```text
user
nice
system
idle
iowait
irq
softirq
steal
guest
guest_nice
```

The aggregate `cpu` line is ignored because the program displays usage separately for each logical CPU core.

## CPU Usage Calculation

The script calculates busy CPU time using:

```text
busy =
    user
  + nice
  + system
  + irq
  + softirq
  + steal
  + guest
  + guest_nice
```

Idle CPU time is calculated using:

```text
idle_total = idle + iowait
```

Because `/proc/stat` contains cumulative CPU counters since system startup, two samples are required.

The script stores the previous sample in:

```bash
declare -A prev_data=()
```

and the current sample in:

```bash
declare -A curr_data=()
```

The differences between consecutive samples are calculated:

```text
busy_difference = current_busy - previous_busy

idle_difference = current_idle - previous_idle
```

Total CPU time during the measurement interval is:

```text
total = busy_difference + idle_difference
```

CPU usage is calculated as:

```text
CPU Usage = busy_difference / total × 100
```

The script uses integer arithmetic scaled by `1000` to display CPU usage with one decimal place:

```bash
usage=$((1000 * busy / total))
```

For example:

```text
usage = 754
```

is displayed as:

```text
75.4%
```

## Progress Bar Calculation

Each CPU core is represented using a 40-character progress bar.

The number of filled positions is calculated using:

```text
number_of_bars = usage × bar_length / 1000
```

For example, approximately 50% CPU utilization produces:

```text
[####################....................]
```

The `#` characters represent the used portion of the progress bar, while the `.` characters represent the remaining portion.

## Terminal Rendering

The program uses ANSI escape sequences to create an interactive terminal interface.

### Enter Alternate Screen Buffer

```bash
printf "\033[?1049h"
```

This switches the terminal to an alternate screen buffer. The original terminal contents are restored when the program exits.

### Hide Cursor

```bash
printf "\033[?25l"
```

This hides the terminal cursor while the monitor is running.

### Move Cursor to Top-Left

```bash
printf "\033[H"
```

This moves the cursor to the top-left corner of the terminal.

### Move Cursor to a Specific Position

```bash
printf "\033[5;1H"
```

This moves the cursor to row 5, column 1, where the CPU progress bars begin.

### Erase the Current Line

```bash
printf "\033[2K"
```

This clears the current terminal line before writing new content.

Instead of clearing the entire terminal every second, the script rewrites existing lines in place. This reduces screen flickering.

## Program Flow

```text
Start Program
      |
      v
Enter Alternate Screen Buffer
      |
      v
Hide Cursor
      |
      v
Read Initial CPU Statistics
      |
      v
Wait 1 Second
      |
      v
Copy Current Statistics to Previous Statistics
      |
      v
Read New CPU Statistics
      |
      v
Calculate CPU Usage
      |
      v
Generate Progress Bars
      |
      v
Update Terminal Output
      |
      v
Wait 1 Second
      |
      +--------------------+
      |                    |
      +------ Repeat <-----+
```

## Functions

### `cleanup()`

Restores the terminal state before the program exits.

It:

- Shows the cursor.
- Leaves the alternate screen buffer.
- Calls `tput cnorm` as an additional cursor restoration mechanism.

### `copy_data()`

Copies CPU statistics from `curr_data` into `prev_data`.

This preserves the previous CPU sample so utilization can be calculated from the difference between consecutive readings.

### `read_proc()`

Reads CPU statistics from `/proc/stat`.

It:

- Ignores non-CPU lines.
- Ignores the aggregate `cpu` line.
- Calculates busy CPU time.
- Calculates idle CPU time.
- Stores statistics for every logical CPU core.
- Detects the total number of logical CPU cores.

### `print_bar()`

Calculates CPU utilization between two samples.

It:

- Reads previous CPU statistics.
- Reads current CPU statistics.
- Calculates CPU time differences.
- Computes CPU usage.
- Generates a 40-character ASCII progress bar.
- Displays CPU usage with one decimal place.

### `draw_header()`

Draws the monitor title at the top of the terminal.

### `create_visual()`

Displays CPU progress bars.

CPU interfaces are sorted numerically using:

```bash
sort -V
```

This ensures that CPU cores appear in the expected order:

```text
cpu0
cpu1
cpu2
...
cpu9
cpu10
cpu11
```

instead of lexicographic ordering such as:

```text
cpu0
cpu1
cpu10
cpu11
cpu2
```

### `main()`

Controls the lifecycle of the program.

It:

1. Enters the alternate screen buffer.
2. Hides the cursor.
3. Reads the initial CPU statistics.
4. Draws the terminal interface.
5. Waits one second.
6. Repeatedly samples CPU statistics.
7. Calculates CPU usage.
8. Updates progress bars.
9. Sleeps for one second between updates.

## Limitations

- Works only on Linux systems that expose CPU statistics through `/proc/stat`.
- CPU usage is calculated using integer arithmetic.
- The progress bar has a fixed width of 40 characters.
- The refresh interval is fixed at one second.
- The program displays per-core usage but does not display aggregate CPU usage.
- The terminal must support ANSI escape sequences.

## Possible Improvements

Future versions could add:

- Aggregate CPU usage.
- Colored progress bars based on CPU utilization.
- Configurable refresh intervals.
- Configurable progress bar width.
- CPU frequency information.
- CPU temperature monitoring.
- Load average statistics.
- Command-line arguments.
- Keyboard controls for changing views.
- Memory and swap monitoring.
- Dynamic handling of terminal resizing
