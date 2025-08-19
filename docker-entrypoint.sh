#!/bin/bash
set -e

# Change ownership of the mounted volume to the fluent user (UID 1000).
chown -R 1000:1000 /fluentd/log

# Execute the main command from the Dockerfile
exec "$@"
