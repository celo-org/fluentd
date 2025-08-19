FROM debian:bullseye

# Install dependencies: ruby for fluentd, python3 for downloader, cron + supervisor
RUN apt-get update && apt-get install -y \
    ruby ruby-dev build-essential \
    python3 python3-pip \
    cron supervisor \
 && gem install fluentd --no-doc \
 && rm -rf /var/lib/apt/lists/*

# Create fluentd user
RUN useradd -m -u 1000 -s /bin/bash fluentd

# Create required directories
RUN mkdir -p /fluentd/etc /fluentd/downloads /var/log/fluentd
RUN chown -R fluentd:fluentd /fluentd /var/log/fluentd

# Copy configs and scripts
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY fluent.conf /fluentd/etc/fluent.conf
COPY downloader.py /fluentd/etc/downloader.py
COPY fluentd-cron /etc/cron.d/fluentd-cron

# Fix permissions
RUN chmod +x /fluentd/etc/downloader.py \
 && chmod 0644 /etc/cron.d/fluentd-cron \
 && crontab /etc/cron.d/fluentd-cron

# Expose Fluentd default port
EXPOSE 24224

# Start supervisor (which manages fluentd + cron)
CMD ["/usr/bin/supervisord", "-n"]

