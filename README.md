# Change Docker Volume Permissions Helper Script
A helpful script for assisting in the migration of serversideup/php v2 → v3.

> [!CAUTION]
> Be sure to have tested backups before running this script. Root permissions are required, and the script will change the ownership of directories within the Docker volumes base directory. Use this script at your own risk.

### Usage
```bash
bash change-volume-permissions.sh --volume-prefix <prefix> --permissions <user:group> [--dry-run]
```

###### Options
- `--volume-prefix`: Specific prefix of directories to search within the Docker volumes base directory."
- `--permissions`: User and group to change ownership to, formatted as user:group."
- `--dry-run`: Optional flag to simulate changes without applying them."

### More help
Read our migration guide: https://serversideup.net/open-source/docker-php/docs/guide/migrating-from-v2-to-v3