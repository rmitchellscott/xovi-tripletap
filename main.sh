#!/bin/bash

# Initialize variables
BUTTON_PRESSES=0
LAST_PRESS_TIME=0
TIME_THRESHOLD=2  # seconds between presses to be considered consecutive
REQUIRED_PRESSES=3
INPUT_DEVICE="/dev/input/event0"  # Change this to match your button device
EVTEST_PATH="/home/root/xovi-tripletap/evtest"  # Change this to your evtest executable path

# Check if evtest executable exists and is executable
if [ ! -x "$EVTEST_PATH" ]; then
    logger "Error: evtest not found or not executable at $EVTEST_PATH"
    exit 1
fi

# Function to run when button sequence is detected
trigger_action() {
    logger "Button sequence detected - running action script"
    /home/root/xovi/start  # Replace with your script path
}

# Monitor input events
"$EVTEST_PATH" "$INPUT_DEVICE" | while read line; do
    # Look for button press events
    if echo "$line" | grep -q "type 1 (EV_KEY), code .*, value 1"; then
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
