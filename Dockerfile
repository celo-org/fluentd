FROM fluent/fluentd:v1.16-debian-1

USER root

# Install cron, python3-pip, and fluent plugin
RUN apt-get update && apt-get install -y python3-pip cron \
 && gem install fluent-plugin-gcloud-pubsub-custom \
 && pip install google-cloud-storage

# Add a user back (if needed)
RUN useradd -u 1000 -r -s /bin/false fluentd

# Copy your script and cron job definition
COPY fluent.conf /fluentd/etc/fluent.conf
COPY downloader.py /fluentd/etc/downloader.py
COPY crontab /etc/cron.d/downloader

# Ensure scripts and cron file have correct permissions
RUN chmod +x /fluentd/etc/downloader.py && chmod 0644 /etc/cron.d/downloader

# Apply the crontab
RUN crontab /etc/cron.d/downloader

# Create a log file
RUN touch /var/log/cron.log

# Switch back to fluentd user
USER fluentd

# Start both Fluentd and cron using a small wrapper script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

