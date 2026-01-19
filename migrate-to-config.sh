#!/bin/bash

# Migration script to move settings from main.sh to config file
# This preserves user customizations during package upgrades

CONFIG_FILE="/home/root/xovi-tripletap/config"
MAIN_SH="/home/root/xovi-tripletap/main.sh"
CONFIG_DEFAULT="/home/root/xovi-tripletap/config.default"

# Skip if config already exists
if [ -f "$CONFIG_FILE" ]; then
    echo "Config file already exists at $CONFIG_FILE, skipping migration"
    exit 0
fi

echo "Migrating settings to config file..."

# Default values
DEFAULT_ENABLE_VERSION_SWITCHING="false"
DEFAULT_TRIGGER_ACTION='"start"'
DEFAULT_TIME_THRESHOLD="2"
DEFAULT_REQUIRED_PRESSES="3"

# Extract current values from main.sh if it exists
if [ -f "$MAIN_SH" ]; then
    ENABLE_VERSION_SWITCHING=$(grep -E '^ENABLE_VERSION_SWITCHING=' "$MAIN_SH" | head -n 1 | cut -d'=' -f2 | cut -d'#' -f1 | tr -d ' ')
    TRIGGER_ACTION=$(grep -E '^TRIGGER_ACTION=' "$MAIN_SH" | head -n 1 | cut -d'=' -f2 | cut -d'#' -f1 | tr -d ' ')
    TIME_THRESHOLD=$(grep -E '^TIME_THRESHOLD=' "$MAIN_SH" | head -n 1 | cut -d'=' -f2 | tr -d ' ' | cut -d'#' -f1 | tr -d ' ')
    REQUIRED_PRESSES=$(grep -E '^REQUIRED_PRESSES=' "$MAIN_SH" | head -n 1 | cut -d'=' -f2 | tr -d ' ' | cut -d'#' -f1 | tr -d ' ')
fi

# Apply defaults for any missing or empty values
ENABLE_VERSION_SWITCHING=${ENABLE_VERSION_SWITCHING:-$DEFAULT_ENABLE_VERSION_SWITCHING}
TRIGGER_ACTION=${TRIGGER_ACTION:-$DEFAULT_TRIGGER_ACTION}
TIME_THRESHOLD=${TIME_THRESHOLD:-$DEFAULT_TIME_THRESHOLD}
REQUIRED_PRESSES=${REQUIRED_PRESSES:-$DEFAULT_REQUIRED_PRESSES}

# Create config file with detected values
cat > "$CONFIG_FILE" << EOF
# xovi-tripletap Configuration File
# Location: /home/root/xovi-tripletap/config
#
# This file contains user-editable settings for xovi-tripletap.
# After making changes, restart the service:
#   systemctl restart xovi-tripletap

# Version switching for qt-resource-rebuilder
# Set to false to disable automatic version detection and switching
ENABLE_VERSION_SWITCHING=${ENABLE_VERSION_SWITCHING}

# Trigger action mode
# "start" - always start xovi (or restart if already running)
# "toggle" - toggle xovi on/off
TRIGGER_ACTION=${TRIGGER_ACTION}

# Triple-tap detection settings
TIME_THRESHOLD=${TIME_THRESHOLD}        # seconds between presses to be considered consecutive
REQUIRED_PRESSES=${REQUIRED_PRESSES}      # number of presses needed to trigger action (2=double-tap, 3=triple-tap, etc.)

# Custom commands to run before starting xovi
# These run in both "start" and "toggle" modes (whenever xovi is being started)
# Commands are executed in order; failures are logged but don't block execution
# Example:
#   PRE_START_COMMANDS=(
#       "/home/root/backup-settings.sh"
#       "logger 'xovi-tripletap: Starting xovi'"
#   )
PRE_START_COMMANDS=()

# Custom commands to run after starting xovi
# These run in both "start" and "toggle" modes (whenever xovi has been started)
# Commands are executed in order; failures are logged
# Example:
#   POST_START_COMMANDS=(
#       "/home/root/send-notification.sh 'xovi started'"
#       "echo 'xovi started at \$(date)' >> /home/root/xovi.log"
#   )
POST_START_COMMANDS=()
EOF

echo "Migration complete: Created $CONFIG_FILE"
echo "Settings migrated from main.sh:"
echo "  ENABLE_VERSION_SWITCHING=${ENABLE_VERSION_SWITCHING}"
echo "  TRIGGER_ACTION=${TRIGGER_ACTION}"
echo "  TIME_THRESHOLD=${TIME_THRESHOLD}"
echo "  REQUIRED_PRESSES=${REQUIRED_PRESSES}"
echo ""
echo "Your settings have been preserved in the config file."
echo "You can now edit $CONFIG_FILE to customize behavior."
