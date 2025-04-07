#!/bin/bash

# Source environment variables
source /backup/.env

# Create mount point if it doesn't exist
mkdir -p "$BIND_MOUNT_POINT" || exit 1

# Create a bind mount of /
mount --bind / "$BIND_MOUNT_POINT" || exit 1 