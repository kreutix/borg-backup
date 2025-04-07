#!/bin/sh

# Source environment variables
source /backup/.env

# Create LVM snapshot
/sbin/lvcreate --snapshot --size "$LVM_SNAPSHOT_SIZE" --name "$LVM_SNAPSHOT_NAME" "$LVM_VOLUME"

# Mount the snapshot read-only
mount -o ro "$LVM_VOLUME"-"$LVM_SNAPSHOT_NAME" "$LVM_MOUNT_POINT"
