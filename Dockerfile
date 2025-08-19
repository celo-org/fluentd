FROM fluent/fluentd:v1.16-debian-1

USER root

# Install packages & gems
RUN apt-get update && apt-get install -y python3-pip cron supervisor \
    && gem install fluent-plugin-gcloud-pubsub-custom \
    && pip install google-cloud-storage

# Create fluentd user & group explicitly
RUN groupadd -r fluentd && useradd -r -g fluentd fluentd

# Prepare log directory and give ownership to fluentd user
RUN mkdir -p /fluentd/log && chown -R fluentd:fluentd /fluentd/log

# Copy Fluentd config, scripts, and supervisord config
COPY fluent.conf /fluentd/etc/fluent.conf
COPY downloader.py /fluentd/etc/downloader.py
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY crontab /etc/cron.d/downloader

# Fix permissions
RUN chmod +x /fluentd/etc/downloader.py \
    && chmod 0644 /etc/cron.d/downloader

# Apply crontab
RUN crontab /etc/cron.d/downloader

# Create a log file for cron logs
RUN touch /var/log/cron.log

# Run supervisord to manage Fluentd and cron
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

