#!/bin/bash

# Start cron
cron

# Start Fluentd
exec fluentd -c /fluentd/etc/fluent.conf -v

