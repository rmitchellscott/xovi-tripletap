# xovi-tripletap
[![rm1](https://img.shields.io/badge/rM1-supported-green)](https://remarkable.com/store/remarkable)
[![rm2](https://img.shields.io/badge/rM2-supported-green)](https://remarkable.com/store/remarkable-2)
[![rmpp](https://img.shields.io/badge/rMPP-supported-green)](https://remarkable.com/products/remarkable-paper/pro)
[![rmppm](https://img.shields.io/badge/rMPPM-supported-green)](https://remarkable.com/products/remarkable-paper/pro-move)

A power button handler for reMarkable devices that enables starting [xovi](https://github.com/asivery/xovi) via a triple-press of the power button.

Original script concept by [@FouzR](https://github.com/FouzR).

> [!NOTE]
> There are several programs (such as freemarkable and readmarkable) that bundle parts or all of xovi-tripletap for installation. I do not recommend them nor provide support for those who choose to use them.

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
  - Support, updates, or bug fixes are provided on a best effort basis with no guarantee of availability or timeline

  **Proceed only if you understand and accept these risks.**

## Installation

### Via [Vellum package manager](https://github.com/vellum-dev/vellum)

`vellum install tripletap`

### Automatic Installation

> [!CAUTION]
> Piping code from the internet directly into `bash` can be dangerous. Make sure you trust the source and know what it will do to your system.

Run the automated installer on your reMarkable device:

```bash
wget -qO- https://raw.githubusercontent.com/rmitchellscott/xovi-tripletap/main/install.sh | bash
```

### Manual Installation

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

The service monitors power button input and triggers xovi when a triple-press is detected. By default, it will always start xovi (or restart it if already running).

## Configuration

All settings are stored in `/home/root/xovi-tripletap/config`. Edit this file to customize behavior:

```bash
nano /home/root/xovi-tripletap/config
```

After making changes, restart the service:
```bash
systemctl restart xovi-tripletap
```

### Available Settings

#### TRIGGER_ACTION
Controls how xovi behaves when triggered:
- `"start"` (default): Always runs `/home/root/xovi/start` when triggered, even if xovi is already running
- `"toggle"`: Toggles xovi - starts it if not running, stops it (runs `/home/root/xovi/stock`) if already running

Example:
```bash
TRIGGER_ACTION="toggle"
```

#### ENABLE_VERSION_SWITCHING
Enable or disable automatic qt-resource-rebuilder version switching (see Version Awareness section below):
- `true` : Enable version switching
- `false`(default): Disable version switching

Example:
```bash
ENABLE_VERSION_SWITCHING=false
```

#### TIME_THRESHOLD
Number of seconds between button presses for them to be considered consecutive. Default is `2`.

Example (tighter timing):
```bash
TIME_THRESHOLD=1
```

#### REQUIRED_PRESSES
Number of button presses needed to trigger the action. Default is `3` (triple-tap).

Examples:
```bash
REQUIRED_PRESSES=2  # Double-tap
REQUIRED_PRESSES=4  # Quad-tap
```

#### PRE_START_COMMANDS
Array of custom commands to run before starting xovi. These run in both "start" and "toggle" modes (whenever xovi is being started). Commands are executed in order; failures are logged but don't block execution.

Example:
```bash
PRE_START_COMMANDS=(
    "/home/root/backup-settings.sh"
    "echo 'xovi-tripletap: Starting xovi'"
)
```

#### POST_START_COMMANDS
Array of custom commands to run after starting xovi. These run in both "start" and "toggle" modes (whenever xovi has been started). Commands are executed in order; failures are logged.

Example:
```bash
POST_START_COMMANDS=(
    "/home/root/send-notification.sh 'xovi started'"
    "echo 'xovi started at $(date)' >> /home/root/xovi.log"
)
```

### Configuration Migration

If you're upgrading from a previous version that used settings in `main.sh`, your settings will be automatically migrated to the new config file during installation. The migration runs automatically when you run `enable.sh` or `install.sh`.

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

## Version Awareness

This feature automatically switches xovi's qt-resource-rebuilder directory between different versions based on your reMarkable's OS version. This is useful when updating your device's firmware or dualbooting, as different OS versions require different hashtabs and may support different qmd files.

### Initial Setup

To enable version switching for qt-resource-rebuilder, run:

```bash
xovi-tripletap/init-version-switching.sh
```

This will:
- Create a version-specific copy of your current qt-resource-rebuilder folder
- Replace the original folder with a symlink that points to the version-specific copy
- Enable automatic version detection and switching

### After OS Updates

When you update your reMarkable's OS version:

1. Run the preparation script:
   ```bash
   xovi-tripletap/prepare-new-version.sh
   ```

2. This creates a new version-specific folder for the new OS version

3. Regenerate hashtabs for the new OS version using your normal xovi workflow

### How It Works

- The version switcher detects your OS version using system configuration files
- When xovi is triggered via triple-tap, it automatically checks if the correct version is linked
- Version-specific folders are named like: `qt-resource-rebuilder-3.22.0.64`
- The system maintains separate hashtabs for each OS version

### Managing Versions

```bash
# List all available versions
xovi-tripletap/prepare-new-version.sh --list

# Manually switch versions (happens automatically on triple-tap)
xovi-tripletap/version-switcher.sh

# Disable version switching and restore qt-resource-rebuilder as a regular folder
xovi-tripletap/disable-version-switching.sh
```

### Disabling Version Switching

If you want to disable version switching and return to a standard qt-resource-rebuilder setup:

```bash
xovi-tripletap/disable-version-switching.sh
```

This will:
- Copy the currently active version back to the main qt-resource-rebuilder location
- Remove the symlink and replace it with a regular directory
- Preserve all version-specific directories (you can manually delete them if desired)

Note: The uninstall script automatically disables version switching to ensure xovi continues working after xovi-tripletap is removed.

### Notes

- Version switching is optional - xovi will continue to work normally without it
- If qt-resource-rebuilder exists as a regular folder (not a symlink), it will be used as-is
- All logs from version switching are captured in journalctl alongside the main service logs

## reMarkable 1
Four times the buttons, four times the fun!

Feel free to tweak the main.sh script to handle other button presses. I've included a press-and-hold.sh script as an example, which lets you configure one of the buttons to launch xovi if you hold it for 3 seconds.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

The included `evtest` binaries are distributed under the GNU General Public License v2.0. Source code for evtest is available at: https://cgit.freedesktop.org/evtest/
