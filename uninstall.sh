#!/bin/bash

set -e

INSTALL_DIR="/home/root/xovi-tripletap"

echo "Stopping xovi-tripletap service..."
systemctl stop xovi-tripletap || true

echo "Disabling xovi-tripletap service..."
systemctl disable xovi-tripletap || true

echo "Detecting device type for filesystem handling..."
if grep -qE "reMarkable (Ferrari|Chiappa)" /proc/device-tree/model 2>/dev/null; then
    echo "Detected reMarkable Paper Pro family - remounting filesystem..."
    mount -o remount,rw /
    umount -R /etc || true
fi

echo "Removing service file..."
rm -f /etc/systemd/system/xovi-tripletap.service

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Checking for version switching..."
if [ -f "$INSTALL_DIR/disable-version-switching.sh" ]; then
    echo "Disabling qt-resource-rebuilder version switching..."
    "$INSTALL_DIR/disable-version-switching.sh" --force
fi

echo "Removing installation directory..."
rm -rf "$INSTALL_DIR"

echo "Uninstall complete!"
echo "xovi-tripletap has been completely removed from your system."
