#!/bin/bash

# Script Name: change-volume-permissions.sh
# Usage: bash change-volume-permissions.sh <prefix> <user:group> [--dry-run]

# Function to show help menu
show_help() {
    echo "Usage: $0 <prefix> <user:group> [--dry-run]"
    echo "prefix       Prefix of directories to search within the Docker volumes base directory."
    echo "user:group   User and group to change ownership to, formatted as user:group."
    echo "--dry-run    Optional flag to simulate changes without applying them."
    exit 1
}

# Check if the script is running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# Check for the correct number of arguments
if [[ $# -lt 2 ]] || [[ $# -gt 3 ]]; then
    show_help
fi

# Assign variables
PREFIX=$1
USER_GROUP=$2
DRY_RUN=$3
DOCKER_VOLUME_BASE_DIR="/var/lib/docker/volumes"

# Check for valid user:group format
if ! [[ $USER_GROUP =~ ^[0-9]+:[0-9]+$ ]]; then
    echo "Error: Invalid user:group format. It should be numeric user ID and group ID."
    show_help
fi

# Display overview of directories to be updated
echo "The following directories will be affected:"
for dir in ${DOCKER_VOLUME_BASE_DIR}/${PREFIX}*; do
    if [[ -d "$dir" && "$(basename "$dir")" = "${PREFIX}"* ]]; then
        echo "${dir}/_data/"
    fi
done

# Prompt for confirmation if not a dry run
if [[ "$DRY_RUN" != "--dry-run" ]]; then
    read -p "Do you want to proceed with changing ownership? (y/N) " -n 1 -r
    echo    # Move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # Handle execution source accordingly.
    fi
fi

# Function to change ownership
change_ownership() {
    local folder=$1
    local user_group=$2
    local dry_run=$3
    local target_path="${DOCKER_VOLUME_BASE_DIR}/${folder}/_data"

    if [[ -d "$target_path" ]]; then
        if [[ "$dry_run" == "--dry-run" ]]; then
            echo "DRY RUN: Would change ownership of $target_path to $user_group"
        else
            chown -R $user_group "$target_path"
        fi
    else
        echo "The path $target_path does not exist."
    fi
}

# Main loop to change ownership if confirmed
if [[ "$DRY_RUN" == "--dry-run" ]] || [[ $REPLY =~ ^[Yy]$ ]]; then
    for dir in ${DOCKER_VOLUME_BASE_DIR}/${PREFIX}*; do
        if [[ -d "$dir" && "$(basename "$dir")" = "${PREFIX}"* ]]; then
            change_ownership "$(basename "$dir")" "$USER_GROUP" "$DRY_RUN"
        fi
    done
fi
