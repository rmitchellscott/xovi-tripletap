#!/bin/bash

# Configuration
ENABLE_VERSION_SWITCHING=true  # Set to false to disable qt-resource-rebuilder version switching

# Initialize variables
BUTTON_PRESSES=0
LAST_PRESS_TIME=0
TIME_THRESHOLD=2  # seconds between presses to be considered consecutive
REQUIRED_PRESSES=3

# Detect device model and set appropriate input device
if grep -q "reMarkable 1.0" /proc/device-tree/model 2>/dev/null; then
    INPUT_DEVICE="/dev/input/event1"
else
    INPUT_DEVICE="/dev/input/event0"
fi

EVTEST_PATH="/home/root/xovi-tripletap/evtest"  # Change this to your evtest executable path

# Check if evtest executable exists and is executable
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

    # Attempt to switch qt-resource-rebuilder version if enabled and function exists
    if [ "$ENABLE_VERSION_SWITCHING" = "true" ] && type switch_qt_resource_version >/dev/null 2>&1; then
        echo "Checking qt-resource-rebuilder version..."
        switch_qt_resource_version
    fi

    /home/root/xovi/start  # Replace with your script path
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
