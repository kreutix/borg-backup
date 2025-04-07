#!/bin/bash

# Source environment variables
source /backup/.env

# Function to exit on error
die() { echo "$1"; exit 1; }

# Cleanup function for interrupts
cleanup() {
    echo "Interrupted! Cleaning up..."
    if [ "$USE_LVM" = "true" ] && [ -e "/dev/$LVM_VG/$LVM_SNAPSHOT_NAME" ]; then
        /backup/remove_snapshot.sh || echo "Failed to remove snapshot, manual cleanup needed"
    else
        /backup/remove_bind_mount.sh || echo "Failed to remove bind mount, manual cleanup needed"
    fi
    exit 1
}

# Trap SIGINT (Ctrl+C) and SIGTERM (kill)
trap cleanup INT TERM

# Default to bind mount if USE_LVM is not set or false
if [ "$USE_LVM" = "true" ]; then
    # Check if all required LVM variables are set
    [ -z "$LVM_VG" ] && die "LVM_VG not set in .env"
    [ -z "$LVM_LV" ] && die "LVM_LV not set in .env"
    [ -z "$LVM_SNAPSHOT_NAME" ] && die "LVM_SNAPSHOT_NAME not set in .env"
    [ -z "$LVM_SNAPSHOT_SIZE" ] && die "LVM_SNAPSHOT_SIZE not set in .env"
    [ -z "$LVM_MOUNT_POINT" ] && die "LVM_MOUNT_POINT not set in .env"

    # Create snapshot
    /backup/create_snapshot.sh || die "Snapshot creation failed"

    # Create backup from snapshot
    /backup/borg.sh create --stats ::$(date +%Y%m%d)_auto "$LVM_MOUNT_POINT" || die "Borg backup failure"

    # Remove snapshot
    /backup/remove_snapshot.sh || die "Snapshot removal failed"
else
    # Default to bind mount if no LVM
    [ -z "$BIND_MOUNT_POINT" ] && die "BIND_MOUNT_POINT not set in .env"

    # Create bind mount
    /backup/create_bind_mount.sh || die "Bind mount creation failed"

    # Create backup from bind mount
    /backup/borg.sh create --stats ::$(date +%Y%m%d)_auto "$BIND_MOUNT_POINT" || die "Borg backup failure"

    # Remove bind mount
    /backup/remove_bind_mount.sh || die "Bind mount removal failed"
fi

# Prune old backups
/backup/borg.sh prune --keep-daily=30 || die "Prune failed"
