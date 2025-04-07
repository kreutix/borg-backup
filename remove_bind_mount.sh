#!/bin/bash

# Source environment variables
source /backup/.env

# Unmount the bind mount
umount "$BIND_MOUNT_POINT" || exit 1 