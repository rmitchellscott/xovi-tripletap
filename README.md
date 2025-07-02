# xovi-tripletap
[![rm1](https://img.shields.io/badge/rM1-supported-green)](https://remarkable.com/store/remarkable)
[![rm2](https://img.shields.io/badge/rM2-supported-green)](https://remarkable.com/store/remarkable-2)
[![rmpp](https://img.shields.io/badge/rMPP-supported-green)](https://remarkable.com/store/overview/remarkable-paper-pro)

A power button handler for reMarkable devices that enables starting [xovi](https://github.com/asivery/xovi) via a triple-press of the power button.

Original script concept by [@FouzR](https://github.com/FouzR).

## Installation

Run the automated installer on your reMarkable device:

```bash
wget -qO- https://raw.githubusercontent.com/rmitchellscott/xovi-tripletap/main/install.sh | bash
```

Or manually:

1. Download the install script:
   ```bash
   wget https://raw.githubusercontent.com/rmitchellscott/xovi-tripletap/main/install.sh
   chmod +x install.sh
   ./install.sh
   ```

The installer will:
- Create `/home/root/xovi-tripletap` directory
- Auto-detect your device architecture and download the appropriate `evtest` binary
- Download all required files
- Set up the systemd service and start it automatically
- Handle reMarkable Paper Pro specific filesystem requirements

## What it does

The service monitors power button input and executes `/home/root/xovi/start` when a triple-press is detected.

## Uninstall

To completely remove xovi-tripletap:

```bash
wget -qO- https://raw.githubusercontent.com/rmitchellscott/xovi-tripletap/main/uninstall.sh | bash
```

Or manually:

```bash
wget https://raw.githubusercontent.com/rmitchellscott/xovi-tripletap/main/uninstall.sh
chmod +x uninstall.sh
./uninstall.sh
```

Or use the local copy:

```bash
/home/root/xovi-tripletap/uninstall.sh
```

## Service management

```bash
# Check status
systemctl status xovi-tripletap

# Stop service
systemctl stop xovi-tripletap

# Start service
systemctl start xovi-tripletap

# Disable service
systemctl disable xovi-tripletap

# View logs
journalctl -u xovi-tripletap -f
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

The included `evtest` binaries are distributed under the GNU General Public License v2.0. Source code for evtest is available at: https://cgit.freedesktop.org/evtest/
