#!/bin/bash

QT_RESOURCE_BASE="/home/root/xovi/exthome/qt-resource-rebuilder"

disable_version_switching() {
    echo "Disabling qt-resource-rebuilder version switching..."

    if [ ! -e "$QT_RESOURCE_BASE" ]; then
        echo "qt-resource-rebuilder not found at $QT_RESOURCE_BASE"
        echo "Nothing to disable."
        return 0
    fi

    if [ ! -L "$QT_RESOURCE_BASE" ]; then
        echo "qt-resource-rebuilder is not a symlink (version switching not enabled)"
        echo "Nothing to disable."
        return 0
    fi

    local current_target=$(readlink "$QT_RESOURCE_BASE")
    if [ ! -d "$current_target" ]; then
        echo "Error: Symlink target does not exist: $current_target" >&2
        echo "Cannot safely disable version switching." >&2
        return 1
    fi

    echo "Current symlink points to: $current_target"
    echo "Restoring qt-resource-rebuilder as a regular directory..."

    local temp_dir="${QT_RESOURCE_BASE}.temp.$$"

    echo "Copying contents from $current_target..."
    cp -a "$current_target" "$temp_dir"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to copy qt-resource-rebuilder contents" >&2
        return 1
    fi

    echo "Removing symlink..."
    rm -f "$QT_RESOURCE_BASE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to remove symlink" >&2
        rm -rf "$temp_dir"
        return 1
    fi

    echo "Moving copied contents to final location..."
    mv "$temp_dir" "$QT_RESOURCE_BASE"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to move qt-resource-rebuilder to final location" >&2
        echo "Attempting to restore symlink..." >&2
        ln -s "$current_target" "$QT_RESOURCE_BASE"
        rm -rf "$temp_dir"
        return 1
    fi

    if [ -d "$QT_RESOURCE_BASE" ] && [ ! -L "$QT_RESOURCE_BASE" ]; then
        echo "Successfully disabled version switching!"
        echo "qt-resource-rebuilder is now a regular directory."
        echo ""
        echo "Version-specific directories still exist and can be manually removed if desired:"
        ls -d ${QT_RESOURCE_BASE}-* 2>/dev/null | while read dir; do
            local version=$(basename "$dir" | sed "s/qt-resource-rebuilder-//")
            local size=$(du -sh "$dir" | cut -f1)
            echo "  - $version (size: $size)"
        done
        echo ""
        echo "To re-enable version switching, run init-version-switching.sh"
    else
        echo "Error: Verification failed - qt-resource-rebuilder may be in an inconsistent state" >&2
        return 1
    fi

    return 0
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Disable qt-resource-rebuilder version switching and restore it as a regular directory."
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo "  -f, --force   Don't prompt for confirmation"
    echo ""
    echo "This script will copy the currently linked version back to the main"
    echo "qt-resource-rebuilder location and remove the symlink."
}

FORCE=false

case "${1:-}" in
    -h|--help)
        show_usage
        exit 0
        ;;
    -f|--force)
        FORCE=true
        ;;
    "")
        ;;
    *)
        echo "Unknown option: $1" >&2
        echo "Use --help for usage information" >&2
        exit 1
        ;;
esac

if [ "$FORCE" != "true" ]; then
    if [ "$EUID" -ne 0 ] && [ "$(uname -m)" != "armv7l" ] && [ "$(uname -m)" != "aarch64" ]; then
        echo "Warning: This script should be run as root on the reMarkable device" >&2
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    if [ -L "$QT_RESOURCE_BASE" ]; then
        echo "This will disable version switching for qt-resource-rebuilder."
        read -p "Are you sure you want to continue? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted by user"
            exit 1
        fi
    fi
fi

disable_version_switching
exit $?