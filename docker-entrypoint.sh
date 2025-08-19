#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# Change ownership of the mounted volume to the fluent user (UID 1000).
# This runs after the volume is mounted.
chown -R 1000:1000 /fluentd/log

# Execute the main command from the Dockerfile
exec "$@"
