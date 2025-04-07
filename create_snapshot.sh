#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Source environment variables
source /backup/.env

# Create mount point if it doesn't exist
mkdir -p "$LVM_MOUNT_POINT" || {
    echo "Failed to create mount point: $LVM_MOUNT_POINT" >&2
    exit 1
}

# Create LVM snapshot
/sbin/lvcreate --snapshot --size "$LVM_SNAPSHOT_SIZE" --name "$LVM_SNAPSHOT_NAME" "/dev/$LVM_VG/$LVM_LV" || {
    echo "Failed to create LVM snapshot" >&2
    exit 1
}

# Mount the snapshot read-only
mount -o ro "/dev/$LVM_VG/$LVM_SNAPSHOT_NAME" "$LVM_MOUNT_POINT" || {
    echo "Failed to mount snapshot" >&2
    exit 1
}
