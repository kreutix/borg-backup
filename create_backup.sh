#!/bin/bash

# Source environment variables
source /backup/.env

# Function to exit on error
die() { echo "$1"; exit 1; }

# Default to no LVM if USE_LVM is not set or false
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
    # Create backup directly from root
    /backup/borg.sh create --stats ::$(date +%Y%m%d)_auto / || die "Borg backup failure"
fi

# Prune old backups
/backup/borg.sh prune --keep-daily=30 || die "Prune failed"
