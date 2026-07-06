````markdown
# Network Bandwidth Visualizer

A lightweight Bash script for visualizing real-time network bandwidth usage on Linux systems.

The script reads network statistics from `/proc/net/dev` and displays the receive, transmit, and total bandwidth usage for each network interface. The output updates approximately every second directly in the terminal.

## Features

- Real-time network bandwidth monitoring.
- Displays bandwidth usage for every network interface.
- Shows:
  - Receive bandwidth.
  - Transmit bandwidth.
  - Total bandwidth.
- Automatically formats bandwidth as:
  - `bps`
  - `kbps`
  - `mbps`
- Updates approximately every second.
- Reads network statistics directly from `/proc/net/dev`.
- Uses Bash associative arrays to store previous interface statistics.
- Uses the terminal alternate screen buffer.
- Hides the terminal cursor while running.
- Restores the terminal state when the program exits.
- Supports disabling colors using the `NO_COLOR` environment variable.
- Requires no third-party libraries.
- Press `q` to exit.

## Requirements

- Linux operating system.
- Bash 4 or later (required for associative arrays).
- Access to `/proc/net/dev`.
- A terminal that supports ANSI escape sequences.

No external dependencies are required.

## Installation

Clone the repository:

```bash
git clone <repository-url>
cd <repository-directory>
cd ./linux-network-visualizer
```

Make the script executable:

```bash
chmod +x script
```

Run the script:

```bash
./script
```

## Usage

Run the network bandwidth visualizer:

```bash
./script
```

You can also run the script explicitly using Bash:

```bash
bash script
```

Press `q` to stop the program.

### Disable Colors

The script supports the `NO_COLOR` environment variable.

Run the program without colored output:

```bash
NO_COLOR=1 ./script
```

## Example Output

```text
      interface         receive        transmit           total
             lo          0  bps          0  bps          0  bps
           eth0        245 kbps         32 kbps        277 kbps
          wlan0          1 mbps        125 kbps          1 mbps
```

The output is refreshed approximately every second.

## How It Works

Linux exposes network interface statistics through the `/proc/net/dev` virtual file.

Example:

```text
Inter-|   Receive                                                |  Transmit
 face |bytes packets errs drop fifo frame compressed multicast   |bytes packets errs drop fifo colls carrier compressed
    lo: 120000  1000    0    0    0     0          0         0    120000  1000    0    0    0     0       0          0
  eth0: 984532  2450    0    0    0     0          0         0    432198  1300    0    0    0     0       0          0
```

The script skips the first two header lines using:

```bash
mapfile -t -s 2 lines < /proc/net/dev
```

Each remaining line represents a network interface.

The script extracts:

```text
Interface Name
Received Bytes
Transmitted Bytes
```

The received byte counter is stored at index `1`:

```bash
rx_bytes=${info[1]}
```

The transmitted byte counter is stored at index `9`:

```bash
tx_bytes=${info[9]}
```

The trailing `:` character is removed from the interface name:

```bash
iface=${iface%:}
```

## Bandwidth Calculation

The values stored in `/proc/net/dev` are cumulative byte counters.

This means they represent the total number of bytes received and transmitted since the network interface became active.

To calculate bandwidth, the script stores the previous values for every network interface in a Bash associative array:

```bash
declare -A DATA=()
```

The previous values are retrieved using:

```bash
old=${DATA[$iface]}
```

The current values are then stored:

```bash
DATA[$iface]="$rx_bytes $tx_bytes"
```

The script calculates the difference between the current and previous measurements:

```text
received byte difference =
current received bytes - previous received bytes

transmitted byte difference =
current transmitted bytes - previous transmitted bytes
```

In the script:

```bash
d_rx_bytes=$((rx_bytes - old_rx_bytes))
d_tx_bytes=$((tx_bytes - old_tx_bytes))
```

The total number of transferred bytes is calculated using:

```bash
d_total_bytes=$((d_rx_bytes + d_tx_bytes))
```

The byte values are converted into bits:

```bash
d_rx_bits=$((d_rx_bytes * 8))
d_tx_bits=$((d_tx_bytes * 8))
d_total_bits=$((d_total_bytes * 8))
```

Because the script waits approximately one second between measurements, these values approximate the network transfer rate in bits per second.

## Bandwidth Formatting

The `format-bits()` function converts raw bit values into human-readable units.

```bash
format-bits() {
    local bits=$1

    if ((bits > 1000000)); then
        echo "$((bits / 1000000)) mbps"
    elif ((bits > 1000)); then
        echo "$((bits / 1000)) kbps"
    else
        echo "$bits  bps"
    fi
}
```

The script uses decimal units:

```text
1 kbps = 1,000 bits per second

1 mbps = 1,000,000 bits per second
```

## Terminal Rendering

The program uses ANSI escape sequences to create an interactive terminal interface.

### Enter Alternate Screen Buffer

```bash
printf '\e[?1049h'
```

This switches the terminal to an alternate screen buffer.

The original terminal contents are restored when the program exits.

### Hide Cursor

```bash
printf '\e[?25l'
```

This hides the terminal cursor while the program is running.

### Move Cursor to the Top-Left

```bash
printf '\e[H'
```

This moves the cursor to the top-left corner of the terminal before the interface is redrawn.

### Leave Alternate Screen Buffer

```bash
printf '\e[?1049l'
```

This returns to the original terminal screen.

### Show Cursor

```bash
printf '\e[?25h'
```

This restores the terminal cursor when the program exits.

## Colors

By default, the script uses ANSI escape sequences to color the terminal output.

The following variables define the colors:

```bash
COLOR=$'\e[36m'
DIM=$'\e[2m'
RST=$'\e[0m'
```

`COLOR` displays interface names using cyan text.

`DIM` displays the table header using dim terminal text.

`RST` resets terminal formatting.

If the `NO_COLOR` environment variable is set, the color variables are disabled:

```bash
if [[ -z $NO_COLOR ]]; then
    COLOR=$'\e[36m'
    DIM=$'\e[2m'
    RST=$'\e[0m'
else
    COLOR=
    DIM=
    RST=
fi
```

Example:

```bash
NO_COLOR=1 ./script
```

## Functions

### `fatal()`

Prints a fatal error message to standard error and terminates the program.

Example:

```bash
fatal 'failed to read proc device'
```

### `format-bits()`

Converts a number of bits into a human-readable bandwidth representation.

Depending on the value, it returns:

```text
bps
kbps
mbps
```

### `process-iface()`

Processes network statistics for a single network interface.

It:

- Receives the interface name.
- Receives cumulative received byte statistics.
- Receives cumulative transmitted byte statistics.
- Retrieves the previous statistics from the `DATA` associative array.
- Stores the current statistics.
- Calculates the differences between consecutive measurements.
- Converts bytes to bits.
- Calculates total network traffic.
- Formats the bandwidth values.
- Prints the results.

### `init-term()`

Initializes the terminal interface.

It:

- Enters the alternate screen buffer.
- Hides the terminal cursor.
- Moves the cursor to the top-left corner.

### `deinit-term()`

Restores the terminal state.

It:

- Leaves the alternate screen buffer.
- Shows the terminal cursor.

### `main()`

Controls the lifecycle of the program.

It:

1. Registers the terminal cleanup function using `trap`.
2. Initializes the terminal.
3. Reads `/proc/net/dev`.
4. Skips the first two header lines.
5. Loops through every network interface.
6. Extracts received and transmitted byte counters.
7. Calculates network bandwidth usage.
8. Displays the results.
9. Waits up to one second for keyboard input.
10. Exits when the user presses `q`.
11. Repeats the process.

## Program Flow

```text
Start Program
      |
      v
Register Cleanup Function
      |
      v
Enter Alternate Screen Buffer
      |
      v
Hide Cursor
      |
      v
Read /proc/net/dev
      |
      v
Skip Header Lines
      |
      v
Read Network Interfaces
      |
      v
Retrieve Previous Counters
      |
      v
Store Current Counters
      |
      v
Calculate Byte Differences
      |
      v
Convert Bytes to Bits
      |
      v
Format Bandwidth Values
      |
      v
Display Results
      |
      v
Wait Up To 1 Second for Input
      |
      +------ q pressed? ------> Exit
      |
      +------ No --------------> Repeat
```
## Limitations

- Works only on Linux systems that expose network statistics through `/proc/net/dev`.
- The first measurement for each interface is calculated against zero, so the initial displayed bandwidth values represent cumulative traffic rather than the actual one-second transfer rate.
- Bandwidth values are displayed using integer arithmetic, so fractional values are discarded.
- Only `bps`, `kbps`, and `mbps` units are supported.
- Values greater than one gigabit per second are still displayed in `mbps`.
- The script assumes that each loop iteration takes approximately one second.
- Network counter resets or interface restarts may produce negative differences.
- The program does not calculate packet rate, dropped packets, or network errors.
- The terminal must support ANSI escape sequences.

## Possible Improvements

Future versions could add:

- Correct handling of the initial bandwidth sample.
- More precise bandwidth calculation using actual elapsed time.
- Decimal bandwidth values.
- `gbps` formatting support.
- Configurable refresh intervals.
- Sorting interfaces by bandwidth usage.
- Filtering specific network interfaces.
- Packet-per-second monitoring.
- Dropped packet and network error statistics.
- Colored bandwidth levels.
- ASCII bandwidth graphs.
- Command-line options.
- Terminal resizing support.


