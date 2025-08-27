#!/bin/bash
# Set permissions on the mounted volume as root
mkdir -p /fluentd/log/github-audit/pub-sub/message_queue
chown -R fluent:fluent /fluentd

# Execute the main command through a shell interpreter
exec gosu fluent /bin/bash -c "/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf -n"
