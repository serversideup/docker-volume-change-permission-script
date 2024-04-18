
#!/bin/bash

# Script Name: change-volume-permissions.sh
# Usage: bash change-volume-permissions.sh --volume-prefix <prefix> --permissions <user:group> [--dry-run]

DOCKER_VOLUME_BASE_DIR=${DOCKER_VOLUME_BASE_DIR:-"/var/lib/docker/volumes"}

# Initialize variables
VOLUME_PREFIX=""
USER_GROUP=""
DRY_RUN=false

# Function to show help menu
show_help() {
    echo
    echo "ℹ️ Usage: $0 --volume-prefix <prefix> --permissions <user:group> [--dry-run]"
    echo "--volume-prefix   Specific prefix of directories to search within the Docker volumes base directory."
    echo "--permissions     User and group to change ownership to, formatted as user:group."
    echo "--dry-run         Optional flag to simulate changes without applying them."
    echo
    echo "👇 Available volume prefixes:"
    list_unique_volume_prefixes
    exit 1
}

list_unique_volume_prefixes() {
    find "${DOCKER_VOLUME_BASE_DIR}" -mindepth 1 -maxdepth 1 -type d \
        -exec basename {} \; | awk -F'_' '{print $1}' | sort | uniq
}

# Check if the script is running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root or with sudo."
    exit 1
fi

# Parse command line options
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --volume-prefix) VOLUME_PREFIX="$2"; shift ;;
        --permissions) USER_GROUP="$2"; shift ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help) show_help ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

# Check if required options are set
if [[ -z "$VOLUME_PREFIX" ]] || [[ -z "$USER_GROUP" ]]; then
    echo "Error: --volume-prefix and --permissions are required."
    show_help
fi

# Check for valid user:group format
if ! [[ $USER_GROUP =~ ^[0-9]+:[0-9]+$ ]]; then
    echo "Error: Invalid user:group format. It should be numeric user ID and group ID."
    show_help
fi

# Display overview of directories to be updated
echo "The following directories with volume prefix '${VOLUME_PREFIX}' will be affected:"
for dir in ${DOCKER_VOLUME_BASE_DIR}/${VOLUME_PREFIX}*; do
    if [[ -d "$dir" && "$(basename "$dir")" = "${VOLUME_PREFIX}"* ]]; then
        echo "${dir}/_data/"
    fi
done

# Prompt for confirmation if not a dry run
if [[ "$DRY_RUN" != "true" ]]; then
    read -p "Are you sure you want to change the ownership of these directories? (y/N) " -n 1 -r
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
        if [[ "$dry_run" == "true" ]]; then
            echo "DRY RUN: Would change ownership of $target_path to $user_group"
        else
            chown -R $user_group "$target_path"
        fi
    else
        echo "The path $target_path does not exist."
    fi
}

# Main loop to change ownership if confirmed
if [[ "$DRY_RUN" == "true" ]] || [[ $REPLY =~ ^[Yy]$ ]]; then
    for dir in ${DOCKER_VOLUME_BASE_DIR}/${VOLUME_PREFIX}*; do
        if [[ -d "$dir" && "$(basename "$dir")" = "${VOLUME_PREFIX}"* ]]; then
            change_ownership "$(basename "$dir")" "$USER_GROUP" "$DRY_RUN"
        fi
    done
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "DRY RUN: No changes were applied."
    else
        echo "✅ Ownership changes applied successfully."
    fi
fi
