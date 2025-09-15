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

prepare_new_version() {
    echo "Preparing qt-resource-rebuilder for new OS version..."

    if [ ! -e "$QT_RESOURCE_BASE" ]; then
        echo "Error: qt-resource-rebuilder not found at $QT_RESOURCE_BASE" >&2
        exit 1
    fi

    if [ ! -L "$QT_RESOURCE_BASE" ]; then
        echo "Error: qt-resource-rebuilder is not a symlink" >&2
        echo "Please run init-version-switching.sh first to enable version switching." >&2
        exit 1
    fi

    source_version_switcher

    local current_version=$(detect_os_version)
    if [ $? -ne 0 ]; then
        echo "Failed to detect OS version" >&2
        exit 1
    fi

    echo "Current OS version: $current_version"

    local versioned_dir="${QT_RESOURCE_BASE}-${current_version}"

    if [ -d "$versioned_dir" ]; then
        echo "Version-specific directory already exists: $versioned_dir"
        read -p "Do you want to recreate it? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Using existing directory. Updating symlink..."
        else
            echo "Recreating version-specific directory..."
            rm -rf "$versioned_dir"

            local current_target=$(readlink "$QT_RESOURCE_BASE")
            if [ -d "$current_target" ]; then
                echo "Copying from current symlink target: $current_target"
                cp -a "$current_target" "$versioned_dir"
            else
                echo "Error: Current symlink target does not exist: $current_target" >&2
                exit 1
            fi
        fi
    else
        local current_target=$(readlink "$QT_RESOURCE_BASE")
        if [ ! -d "$current_target" ]; then
            echo "Error: Current symlink target does not exist: $current_target" >&2
            exit 1
        fi

        echo "Creating new version-specific directory: $versioned_dir"
        echo "Copying from: $current_target"
        cp -a "$current_target" "$versioned_dir"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to copy qt-resource-rebuilder to $versioned_dir" >&2
            exit 1
        fi
    fi

    echo "Updating symlink to point to new version..."
    rm -f "$QT_RESOURCE_BASE"
    ln -s "$versioned_dir" "$QT_RESOURCE_BASE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to update symlink" >&2
        exit 1
    fi

    echo "Successfully prepared qt-resource-rebuilder for version $current_version!"
    echo ""
    echo "Current setup:"
    echo "  - Symlink: $QT_RESOURCE_BASE"
    echo "  - Points to: $versioned_dir"
    echo ""
    echo "You can now regenerate hashtabs for the new OS version."
    echo ""

    echo "Available version-specific directories:"
    ls -d ${QT_RESOURCE_BASE}-* 2>/dev/null | while read dir; do
        local version=$(basename "$dir" | sed "s/qt-resource-rebuilder-//")
        if [ "$dir" = "$versioned_dir" ]; then
            echo "  * $version (current)"
        else
            echo "    $version"
        fi
    done
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Prepare qt-resource-rebuilder for a new OS version."
    echo "This creates a version-specific copy and updates the symlink."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo "  -l, --list    List all available versions"
    echo ""
    echo "After running this script, you can regenerate hashtabs"
    echo "for the new OS version using your normal workflow."
}

list_versions() {
    echo "Available qt-resource-rebuilder versions:"

    if [ -L "$QT_RESOURCE_BASE" ]; then
        local current_target=$(readlink "$QT_RESOURCE_BASE")
        echo "Current symlink points to: $current_target"
        echo ""
    fi

    ls -d ${QT_RESOURCE_BASE}-* 2>/dev/null | while read dir; do
        local version=$(basename "$dir" | sed "s/qt-resource-rebuilder-//")
        local size=$(du -sh "$dir" | cut -f1)
        echo "  - $version (size: $size)"
    done

    if [ ! -L "$QT_RESOURCE_BASE" ] && [ -d "$QT_RESOURCE_BASE" ]; then
        echo ""
        echo "Note: Version switching is not enabled."
        echo "Run init-version-switching.sh to enable it."
    fi
}

case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    -l|--list)
        list_versions
        exit 0
        ;;
    "")
        if [ "$EUID" -ne 0 ] && [ "$(uname -m)" != "armv7l" ] && [ "$(uname -m)" != "aarch64" ]; then
            echo "Warning: This script should be run as root on the reMarkable device" >&2
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
        prepare_new_version
        ;;
    *)
        echo "Unknown option: $1" >&2
        echo "Use --help for usage information" >&2
        exit 1
        ;;
esac