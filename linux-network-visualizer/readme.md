# Network Bandwidth Visualizer

A lightweight Bash script for visualizing real-time network bandwidth usage on Linux systems.

The script reads network statistics from `/proc/net/dev` and displays the receive, transmit, and total bandwidth usage for each network interface. The output updates every second directly in the terminal.

## Features

- Real-time network bandwidth monitoring.
- Displays bandwidth for every network interface.
- Shows:
  - Receive bandwidth.
  - Transmit bandwidth.
  - Total bandwidth.
- Automatically formats bandwidth as:
  - `bps`
  - `kbps`
  - `mbps`
- Updates every second.
- Uses the terminal alternate screen buffer.
- Hides the cursor while running.
- Restores the terminal state when the program exits.
- Supports disabling colors using the `NO_COLOR` environment variable.
- Press `q` to exit.

## Requirements

- Linux operating system.
- Bash 4 or later (required for associative arrays).
- Access to `/proc/net/dev`.

No external dependencies are required.

## Installation

Clone the repository:

```bash
git clone <repository-url>
cd <repository-directory>
cd ./linux-network-visualizer
chmod +x script
./script
```
