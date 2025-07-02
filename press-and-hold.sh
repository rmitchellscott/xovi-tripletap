#!/bin/bash

# Initialize variables
TARGET_KEY="KEY_LEFT"  # Configurable key to monitor (KEY_HOME, KEY_LEFT, KEY_RIGHT, KEY_POWER, KEY_WAKEUP)
HOLD_TIME=3           # Hold time in seconds

# Key name to code mapping
get_key_code() {
    case "$1" in
        "KEY_HOME") echo "102" ;;
        "KEY_LEFT") echo "105" ;;
        "KEY_RIGHT") echo "106" ;;
        "KEY_POWER") echo "116" ;;
        "KEY_WAKEUP") echo "143" ;;
        *) 
            echo "Error: Unknown key '$1'. Supported keys: KEY_HOME, KEY_LEFT, KEY_RIGHT, KEY_POWER, KEY_WAKEUP"
            exit 1
            ;;
    esac
}

# Get the key code for the target key
TARGET_KEY_CODE=$(get_key_code "$TARGET_KEY")

# Detect device model and set appropriate input device
if grep -q "reMarkable 1.0" /proc/device-tree/model 2>/dev/null; then
    INPUT_DEVICE="/dev/input/event1"
else
    INPUT_DEVICE="/dev/input/event0"
fi

EVTEST_PATH="/home/root/xovi-tripletap/evtest" 

# Check if evtest executable exists and is executable
if [ ! -x "$EVTEST_PATH" ]; then
    echo "Error: evtest not found or not executable at $EVTEST_PATH"
    exit 1
fi

# Function to run when button hold is detected
trigger_action() {
    echo "Button hold detected - running action script"
    /home/root/xovi/start
}

# Variables to track button state
BUTTON_PRESSED=0
PRESS_START_TIME=0
ACTION_TRIGGERED=0

echo "Monitoring for $TARGET_KEY (code $TARGET_KEY_CODE) hold for ${HOLD_TIME} seconds..."

# Monitor input events with timeout to check hold duration
"$EVTEST_PATH" "$INPUT_DEVICE" | while IFS= read -t 1 line || true; do
    CURRENT_TIME=$(date +%s)
    
    # Check if button is currently held long enough (but action not yet triggered)
    if [ $BUTTON_PRESSED -eq 1 ] && [ $ACTION_TRIGGERED -eq 0 ]; then
        HOLD_DURATION=$((CURRENT_TIME - PRESS_START_TIME))
        if [ $HOLD_DURATION -ge $HOLD_TIME ]; then
            trigger_action
            ACTION_TRIGGERED=1
        fi
    fi
    
    # Process the line if we got one (not a timeout)
    if [ -n "$line" ]; then
        # Look for target key press events (value 1 = press, value 0 = release)
        if echo "$line" | grep -q "type 1 (EV_KEY), code $TARGET_KEY_CODE.*, value 1"; then
            # Button pressed
            if [ $BUTTON_PRESSED -eq 0 ]; then  # Only reset on new press
                BUTTON_PRESSED=1
                PRESS_START_TIME=$CURRENT_TIME
                ACTION_TRIGGERED=0
            fi
            
        elif echo "$line" | grep -q "type 1 (EV_KEY), code $TARGET_KEY_CODE.*, value 0"; then
            # Button released
            if [ $BUTTON_PRESSED -eq 1 ]; then
                BUTTON_PRESSED=0
                HOLD_DURATION=$((CURRENT_TIME - PRESS_START_TIME))
                ACTION_TRIGGERED=0  # Reset for next press
            fi
        fi
    fi
done
