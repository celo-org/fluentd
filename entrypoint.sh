#!/bin/bash

# Start cron (as root)
cron

# Run Fluentd as fluentd user
exec su fluentd -s /bin/bash -c "fluentd -c /fluentd/etc/fluent.conf -v"

