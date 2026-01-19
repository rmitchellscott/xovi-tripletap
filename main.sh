#!/bin/bash

# Default configuration values. Do not edit, use config file instead
DEFAULT_ENABLE_VERSION_SWITCHING=false
DEFAULT_TRIGGER_ACTION="start"
DEFAULT_TIME_THRESHOLD=2
DEFAULT_REQUIRED_PRESSES=3

# Load user configuration
CONFIG_FILE="/home/root/xovi-tripletap/config"
if [ -f "$CONFIG_FILE" ]; then
    if source "$CONFIG_FILE" 2>/dev/null; then
        echo "Configuration loaded from $CONFIG_FILE"
    else
        echo "Error: Config file is malformed, using defaults"
        ENABLE_VERSION_SWITCHING=$DEFAULT_ENABLE_VERSION_SWITCHING
        TRIGGER_ACTION=$DEFAULT_TRIGGER_ACTION
        TIME_THRESHOLD=$DEFAULT_TIME_THRESHOLD
        REQUIRED_PRESSES=$DEFAULT_REQUIRED_PRESSES
    fi
else
    echo "Config file not found, creating from defaults..."
    SCRIPT_DIR="$(dirname "$0")"
    if [ -f "$SCRIPT_DIR/migrate-to-config.sh" ]; then
        bash "$SCRIPT_DIR/migrate-to-config.sh"
        source "$CONFIG_FILE"
    else
        echo "Warning: migrate-to-config.sh not found, using in-memory defaults"
        ENABLE_VERSION_SWITCHING=$DEFAULT_ENABLE_VERSION_SWITCHING
        TRIGGER_ACTION=$DEFAULT_TRIGGER_ACTION
        TIME_THRESHOLD=$DEFAULT_TIME_THRESHOLD
        REQUIRED_PRESSES=$DEFAULT_REQUIRED_PRESSES
    fi
fi

# Apply defaults for any missing variables
: ${ENABLE_VERSION_SWITCHING:=$DEFAULT_ENABLE_VERSION_SWITCHING}
: ${TRIGGER_ACTION:=$DEFAULT_TRIGGER_ACTION}
: ${TIME_THRESHOLD:=$DEFAULT_TIME_THRESHOLD}
: ${REQUIRED_PRESSES:=$DEFAULT_REQUIRED_PRESSES}
: ${PRE_START_COMMANDS:=()}
: ${POST_START_COMMANDS:=()}

# Initialize runtime variables
BUTTON_PRESSES=0
LAST_PRESS_TIME=0

# Detect device model and set appropriate input device
if grep -q "reMarkable 1.0" /proc/device-tree/model 2>/dev/null; then
    INPUT_DEVICE="/dev/input/event1"
else
    INPUT_DEVICE="/dev/input/event0"
fi

EVTEST_PATH="/home/root/xovi-tripletap/evtest"

if [ ! -x "$EVTEST_PATH" ]; then
    echo "Error: evtest not found or not executable at $EVTEST_PATH"
    exit 1
fi

# Source version switcher if available and enabled
if [ "$ENABLE_VERSION_SWITCHING" = "true" ] && [ -f "/home/root/xovi-tripletap/version-switcher.sh" ]; then
    source /home/root/xovi-tripletap/version-switcher.sh
fi

# Function to run when button sequence is detected
trigger_action() {
    echo "Button sequence detected - running action script"

    # Check qt-resource-rebuilder version if enabled
    if [ "$ENABLE_VERSION_SWITCHING" = "true" ] && type switch_qt_resource_version >/dev/null 2>&1; then
        echo "Checking qt-resource-rebuilder version..."
        switch_qt_resource_version
    fi

    # Handle toggle mode
    if [ "$TRIGGER_ACTION" = "toggle" ]; then
        # Check if xovi is running by looking for the LD_PRELOAD in service environment
        if systemctl show xochitl.service --property=Environment | grep -q "LD_PRELOAD=/home/root/xovi/xovi.so"; then
            echo "xovi is currently running - disabling it"
            /home/root/xovi/stock
        else
            echo "xovi is not running - starting it"

            # Run pre-start commands
            for cmd in "${PRE_START_COMMANDS[@]}"; do
                echo "Running pre-start command: $cmd"
                eval "$cmd" || echo "Warning: Pre-start command failed (continuing anyway)"
            done

            # Start xovi
            /home/root/xovi/start

            # Run post-start commands
            for cmd in "${POST_START_COMMANDS[@]}"; do
                echo "Running post-start command: $cmd"
                eval "$cmd" || echo "Warning: Post-start command failed"
            done
        fi
    else
        # Default "start" mode - always run start

        # Run pre-start commands
        for cmd in "${PRE_START_COMMANDS[@]}"; do
            echo "Running pre-start command: $cmd"
            eval "$cmd" || echo "Warning: Pre-start command failed (continuing anyway)"
        done

        # Start xovi
        /home/root/xovi/start

        # Run post-start commands
        for cmd in "${POST_START_COMMANDS[@]}"; do
            echo "Running post-start command: $cmd"
            eval "$cmd" || echo "Warning: Post-start command failed"
        done
    fi
}

# Monitor input events
"$EVTEST_PATH" "$INPUT_DEVICE" | while read line; do
    # Look for button press events (key code 116 only)
    if echo "$line" | grep -q "type 1 (EV_KEY), code 116.*, value 1"; then
        CURRENT_TIME=$(date +%s)
        
        # Check if this press is within the time threshold of the last press
        if [ $((CURRENT_TIME - LAST_PRESS_TIME)) -le $TIME_THRESHOLD ]; then
            BUTTON_PRESSES=$((BUTTON_PRESSES + 1))
        else
            BUTTON_PRESSES=1
        fi
        
        LAST_PRESS_TIME=$CURRENT_TIME
        
        # Check if we've reached the required number of presses
        if [ $BUTTON_PRESSES -eq $REQUIRED_PRESSES ]; then
            trigger_action
            BUTTON_PRESSES=0
        fi
    fi
done
