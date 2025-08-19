FROM fluent/fluentd:v1.19.0-debian

# Install dependencies
RUN apt-get update && apt-get install -y \
    ruby-full \
    python3-pip \
    cron \
    supervisor \
 && gem install fluentd --no-document \
 && gem install fluent-plugin-gcloud-pubsub --no-document \
 && pip3 install --no-cache-dir google-cloud-storage \
 && rm -rf /var/lib/apt/lists/*


# Create fluentd user
RUN useradd -m -u 1000 -s /bin/bash fluentd

# Create directories with correct ownership
RUN mkdir -p /fluentd/etc /fluentd/log /var/log/fluentd \
 && chown -R fluentd:fluentd /fluentd /var/log/fluentd



# Copy configs and scripts
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY fluent.conf /fluentd/etc/fluent.conf
COPY downloader.py /fluentd/etc/downloader.py
COPY fluentd-cron /etc/cron.d/fluentd-cron

# Fix permissions
RUN chmod +x /fluentd/etc/downloader.py \
 && chmod 0644 /etc/cron.d/fluentd-cron

# Expose Fluentd port
EXPOSE 24224

# Run everything as the fluentd user
USER fluentd
# Start supervisor (manages fluentd + cron)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf", "-n"]

