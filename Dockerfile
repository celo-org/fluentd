FROM debian:bullseye

# Install dependencies
RUN apt-get update && apt-get install -y \
    ruby ruby-dev build-essential \
    python3 python3-pip \
    cron supervisor \
 && gem install fluentd --no-doc \
 && gem install fluent-plugin-gcloud-pubsub --no-document \
 && rm -rf /var/lib/apt/lists/*

# Create fluentd user
RUN useradd -m -u 1000 -s /bin/bash fluentd

# Create dirs
RUN mkdir -p /fluentd/etc /fluentd/downloads /fluentd/log /var/log/supervisor \
 && chown -R fluentd:fluentd /fluentd /var/log/supervisor

# Copy configs and scripts
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY fluent.conf /fluentd/etc/fluent.conf
COPY downloader.py /fluentd/etc/downloader.py
COPY fluentd-cron /etc/cron.d/fluentd-cron

# Fix perms
RUN chmod +x /fluentd/etc/downloader.py \
 && chmod 0644 /etc/cron.d/fluentd-cron \
 && crontab -u fluentd /etc/cron.d/fluentd-cron

# Expose Fluentd port
EXPOSE 24224

# Run supervisord as fluentd
USER fluentd
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf", "-n"]

