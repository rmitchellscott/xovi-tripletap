#!/bin/bash

QT_RESOURCE_BASE="/home/root/xovi/exthome/qt-resource-rebuilder"

detect_os_version() {
    local version=$(
        (grep 'RELEASE_VERSION=' /usr/share/remarkable/update.conf 2>/dev/null || \
         grep 'IMG_VERSION=' /etc/os-release 2>/dev/null) | \
        head -n 1 | \
        sed 's/.*=//;s/"//g'
    )

    if [ -z "$version" ]; then
        echo "Error: Could not detect OS version" >&2
        return 1
    fi

    echo "$version"
}

find_best_matching_version() {
    local current_version="$1"
    local base_dir=$(dirname "$QT_RESOURCE_BASE")

    if [ -d "${QT_RESOURCE_BASE}-${current_version}" ]; then
        echo "${QT_RESOURCE_BASE}-${current_version}"
        return 0
    fi

    local major_minor=$(echo "$current_version" | cut -d. -f1-2)
    if [ -d "${QT_RESOURCE_BASE}-${major_minor}" ]; then
        echo "${QT_RESOURCE_BASE}-${major_minor}"
        return 0
    fi

    return 1
}

switch_qt_resource_version() {
    if [ ! -e "$QT_RESOURCE_BASE" ]; then
        echo "Warning: qt-resource-rebuilder not found at $QT_RESOURCE_BASE" >&2
        return 1
    fi

    if [ ! -L "$QT_RESOURCE_BASE" ]; then
        echo "qt-resource-rebuilder exists and is not a symlink, using as-is"
        return 0
    fi

    local current_version=$(detect_os_version)
    if [ $? -ne 0 ]; then
        echo "Failed to detect OS version, cannot switch qt-resource-rebuilder" >&2
        return 1
    fi

    echo "Detected OS version: $current_version"

    local target_dir=$(find_best_matching_version "$current_version")
    if [ $? -ne 0 ]; then
        echo "No version-specific qt-resource-rebuilder found for version $current_version" >&2

        local available_versions=$(ls -d ${QT_RESOURCE_BASE}-* 2>/dev/null | xargs -n1 basename | sed 's/qt-resource-rebuilder-//' | tr '\n' ' ')
        if [ -n "$available_versions" ]; then
            echo "Available versions: $available_versions" >&2
        fi
        return 1
    fi

    if [ ! -d "$target_dir" ]; then
        echo "Error: Target directory $target_dir does not exist" >&2
        return 1
    fi

    local current_target=$(readlink "$QT_RESOURCE_BASE" 2>/dev/null)
    if [ "$current_target" = "$target_dir" ]; then
        echo "qt-resource-rebuilder already pointing to correct version: $target_dir"
        return 0
    fi

    echo "Switching qt-resource-rebuilder to version: $(basename "$target_dir")"
    rm -f "$QT_RESOURCE_BASE"
    ln -s "$target_dir" "$QT_RESOURCE_BASE"

    if [ $? -eq 0 ]; then
        echo "Successfully switched qt-resource-rebuilder to $target_dir"
        return 0
    else
        echo "Error: Failed to create symlink" >&2
        return 1
    fi
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    switch_qt_resource_version
    exit $?
fi