#!/bin/bash

# Source environment variables
source /backup/.env

borg $*
