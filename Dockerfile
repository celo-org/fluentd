FROM fluent/fluentd:v1.16-debian-1

USER root

# Install dependencies: python3-pip, cron, supervisor
RUN apt-get update && apt-get install -y python3-pip cron supervisor \
  && gem install fluent-plugin-gcloud-pubsub-custom \
  && pip install google-cloud-storage \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Make sure /fluentd/log exists and is writable by fluentd user
RUN mkdir -p /fluentd/log \
  && chown -R fluent:fluent /fluentd/log

# Copy Fluentd config and your script
COPY fluent.conf /fluentd/etc/fluent.conf
COPY downloader.py /fluentd/etc/downloader.py

# Copy cron job file and set permissions
COPY crontab /etc/cron.d/downloader
RUN chmod 0644 /etc/cron.d/downloader \
  && crontab /etc/cron.d/downloader

# Copy supervisord config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create cron log file and set permissions
RUN touch /var/log/cron.log \
  && chown fluent:fluent /var/log/cron.log

# Set permissions for your script
RUN chmod +x /fluentd/etc/downloader.py \
  && chown fluent:fluent /fluentd/etc/downloader.py

# Switch to fluent user
USER fluent

# Start supervisord (which starts cron and fluentd)
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

