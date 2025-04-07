#!/bin/sh

# Source environment variables
source /backup/.env

# Unmount the snapshot
umount "$LVM_MOUNT_POINT" || exit 1

# Remove the LVM snapshot
/sbin/lvremove -f "/dev/$LVM_VG/$LVM_SNAPSHOT_NAME" || exit 1
