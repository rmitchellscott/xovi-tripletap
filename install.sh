#!/bin/bash

set -e

REPO="rmitchellscott/xovi-tripletap"
INSTALL_DIR="/home/root/xovi-tripletap"

echo "Creating installation directory..."
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo "Checking for latest release..."
LATEST_RELEASE=$(wget -qO- "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null | grep -o '"tag_name": "[^"]*' | grep -o '[^"]*$' 2>/dev/null || echo "")

if [ -n "$LATEST_RELEASE" ]; then
    echo "Downloading release: $LATEST_RELEASE"
    wget -O release.zip "https://github.com/$REPO/archive/refs/tags/$LATEST_RELEASE.zip"
    unzip -q release.zip
    SOURCE_DIR="xovi-tripletap-${LATEST_RELEASE#v}"
else
    echo "No releases found, downloading main branch"
    wget -O main.zip "https://github.com/$REPO/archive/refs/heads/main.zip"
    unzip -q main.zip
    SOURCE_DIR="xovi-tripletap-main"
fi

echo "Detecting system architecture..."
ARCH=$(uname -m)
case $ARCH in
    armv7l|armhf)
        EVTEST_ARCH="arm32"
        ;;
    aarch64|arm64)
        EVTEST_ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Copying files from downloaded source..."
cp "$SOURCE_DIR/evtest.$EVTEST_ARCH" evtest
chmod +x evtest

cp "$SOURCE_DIR/xovi-tripletap.service" .
cp "$SOURCE_DIR/main.sh" .
chmod +x main.sh

cp "$SOURCE_DIR/enable.sh" .
chmod +x enable.sh

cp "$SOURCE_DIR/uninstall.sh" .
chmod +x uninstall.sh

echo "Cleaning up temporary files..."
rm -rf "$SOURCE_DIR" *.zip

echo "Running enable script..."
./enable.sh

echo "Installation complete!"
