#!/bin/bash
set -e

# Change ownership of the mounted volume to the fluent user (by name).
chown -R fluent:fluent /fluentd/log

# Execute the main command from the Dockerfile
exec "$@"
