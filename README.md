# xovi-tripletap
[![rm1](https://img.shields.io/badge/rM1-supported-green)](https://remarkable.com/store/remarkable)
[![rm2](https://img.shields.io/badge/rM2-supported-green)](https://remarkable.com/store/remarkable-2)
[![rmpp](https://img.shields.io/badge/rMPP-supported-green)](https://remarkable.com/store/overview/remarkable-paper-pro)

A power button handler for reMarkable devices that enables starting [xovi](https://github.com/asivery/xovi) via a triple-press of the power button.

Original script concept by [@FouzR](https://github.com/FouzR).

## Disclaimer

  **USE AT YOUR OWN RISK**

  This software is provided "as is" without warranty of any kind, express or implied. The author makes no representations or warranties regarding
  the safety, reliability, or suitability of this software for any purpose.

  By using this software, you acknowledge and agree that:

  - You use this software entirely at your own risk
  - The author shall not be held liable for any damage, loss of data, device malfunction, or other issues that may arise from the use of this
  software
  - This software modifies system files and services on your reMarkable device, which could potentially cause system instability
  - You are responsible for backing up your device and data before installation
  - You understand that installing third-party software on your reMarkable device
  - Support, updates, or bug fixes are provided on a best effort basis with no guarantee of availability or timeline

  **Proceed only if you understand and accept these risks.**

## Installation

> [!CAUTION]
> Piping code from the internet directly into `bash` can be dangerous. Make sure you trust the source and know what it will do to your system.

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

## reMarkable 1
Four times the buttons, four times the fun!

Feel free to tweak the main.sh script to handle other button presses. I've included a press-and-hold.sh script as an example, which lets you configure one of the buttons to launch xovi if you hold it for 3 seconds.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

The included `evtest` binaries are distributed under the GNU General Public License v2.0. Source code for evtest is available at: https://cgit.freedesktop.org/evtest/
