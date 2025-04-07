#!/bin/bash

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Source environment variables
source /backup/.env

# Unmount the snapshot
umount "$LVM_MOUNT_POINT" || {
    echo "Failed to unmount snapshot: $LVM_MOUNT_POINT" >&2
    exit 1
}

# Remove the LVM snapshot
/sbin/lvremove -f "/dev/$LVM_VG/$LVM_SNAPSHOT_NAME" || {
    echo "Failed to remove LVM snapshot" >&2
    exit 1
}
