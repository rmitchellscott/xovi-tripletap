#!/bin/bash

set -e

INSTALL_DIR="/home/root/xovi-tripletap"

echo "Stopping xovi-tripletap service..."
systemctl stop xovi-tripletap || true

echo "Disabling xovi-tripletap service..."
systemctl disable xovi-tripletap || true

echo "Detecting device type for filesystem handling..."
if grep -q "reMarkable Paper Pro" /proc/device-tree/model 2>/dev/null; then
    echo "Detected reMarkable Paper Pro - remounting filesystem..."
    mount -o remount,rw /
    umount -R /etc || true
fi

echo "Removing service file..."
rm -f /etc/systemd/system/xovi-tripletap.service

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Removing installation directory..."
rm -rf "$INSTALL_DIR"

echo "Uninstall complete!"
echo "xovi-tripletap has been completely removed from your system."