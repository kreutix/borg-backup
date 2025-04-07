#!/bin/sh

# Source environment variables
source /backup/.env

borg $*
