#!/bin/sh

# Source environment variables
source /backup/.env

# Unmount the snapshot
umount "$LVM_MOUNT_POINT"

# Remove the LVM snapshot
/sbin/lvremove -f "$LVM_VOLUME"-"$LVM_SNAPSHOT_NAME"
