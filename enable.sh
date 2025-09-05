#!/bin/bash

set -e

echo "Detecting device type..."
if grep -qE "reMarkable (Ferrari|Chiappa)" /proc/device-tree/model 2>/dev/null; then
    echo "Detected reMarkable Paper Pro family - remounting filesystem..."
    mount -o remount,rw /
    umount -R /etc || true
fi

echo "Installing systemd service..."
cp /home/root/xovi-tripletap/xovi-tripletap.service /etc/systemd/system/

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling and starting xovi-tripletap service..."
systemctl enable xovi-tripletap --now

echo "Service installation complete!"
echo "Re-run xovi-tripletap/enable.sh after software updates."
