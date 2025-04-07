#!/bin/bash

# Source environment variables
source /backup/.env

# Function to exit on error
die() { echo "$1"; exit 1; }

# Default to no LVM if USE_LVM is not set or false
if [ "$USE_LVM" = "true" ]; then
    # Create snapshot
    /backup/create_snapshot.sh || die "Snapshot creation failed"

    # Create backup from snapshot
    /backup/borg.sh create --stats ::$(date +%Y%m%d)_auto /backup/root.snapshot || die "Borg backup failure"

    # Remove snapshot
    /backup/remove_snapshot.sh || die "Snapshot removal failed"
else
    # Create backup directly from root
    /backup/borg.sh create --stats ::$(date +%Y%m%d)_auto / || die "Borg backup failure"
fi

# Prune old backups
/backup/borg.sh prune --keep-daily=30 || die "Prune failed"
