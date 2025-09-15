#!/bin/bash

QT_RESOURCE_BASE="/home/root/xovi/exthome/qt-resource-rebuilder"

source_version_switcher() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$script_dir/version-switcher.sh" ]; then
        source "$script_dir/version-switcher.sh"
    elif [ -f "/home/root/xovi-tripletap/version-switcher.sh" ]; then
        source "/home/root/xovi-tripletap/version-switcher.sh"
    else
        echo "Error: version-switcher.sh not found" >&2
        exit 1
    fi
}

initialize_version_switching() {
    echo "Initializing qt-resource-rebuilder version switching..."

    if [ ! -d "$QT_RESOURCE_BASE" ]; then
        echo "Error: qt-resource-rebuilder not found at $QT_RESOURCE_BASE" >&2
        echo "Please ensure xovi is installed first." >&2
        exit 1
    fi

    if [ -L "$QT_RESOURCE_BASE" ]; then
        echo "Error: qt-resource-rebuilder is already a symlink" >&2
        echo "Version switching appears to be already initialized." >&2

        local current_target=$(readlink "$QT_RESOURCE_BASE")
        echo "Currently pointing to: $current_target" >&2
        exit 1
    fi

    source_version_switcher

    local current_version=$(detect_os_version)
    if [ $? -ne 0 ]; then
        echo "Failed to detect OS version" >&2
        exit 1
    fi

    echo "Detected OS version: $current_version"

    local versioned_dir="${QT_RESOURCE_BASE}-${current_version}"

    if [ -d "$versioned_dir" ]; then
        echo "Warning: Version-specific directory already exists: $versioned_dir" >&2
        read -p "Overwrite existing directory? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted by user" >&2
            exit 1
        fi
        rm -rf "$versioned_dir"
    fi

    echo "Creating version-specific directory: $versioned_dir"
    cp -a "$QT_RESOURCE_BASE" "$versioned_dir"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy qt-resource-rebuilder to $versioned_dir" >&2
        exit 1
    fi

    echo "Removing original qt-resource-rebuilder directory..."
    rm -rf "$QT_RESOURCE_BASE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to remove original directory" >&2
        echo "Attempting to restore..." >&2
        rm -rf "$versioned_dir"
        exit 1
    fi

    echo "Creating symlink: $QT_RESOURCE_BASE -> $versioned_dir"
    ln -s "$versioned_dir" "$QT_RESOURCE_BASE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create symlink" >&2
        echo "Attempting to restore original directory..." >&2
        cp -a "$versioned_dir" "$QT_RESOURCE_BASE"
        rm -rf "$versioned_dir"
        exit 1
    fi

    if [ -L "$QT_RESOURCE_BASE" ] && [ -d "$versioned_dir" ]; then
        echo "Successfully initialized version switching!"
        echo "qt-resource-rebuilder is now version-aware."
        echo ""
        echo "Created:"
        echo "  - Version-specific directory: $versioned_dir"
        echo "  - Symlink: $QT_RESOURCE_BASE -> $versioned_dir"
        echo ""
        echo "To prepare for a new OS version, run prepare-new-version.sh"
        echo ""
        echo "Restarting xovi-tripletap service..."
        systemctl restart xovi-tripletap
        echo "Service restarted successfully."
    else
        echo "Error: Initialization verification failed" >&2
        exit 1
    fi
}

if [ "$EUID" -ne 0 ] && [ "$(uname -m)" != "armv7l" ] && [ "$(uname -m)" != "aarch64" ]; then
    echo "Warning: This script should be run as root on the reMarkable device" >&2
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

initialize_version_switching