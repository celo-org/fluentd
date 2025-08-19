FROM debian:bullseye

# Install dependencies: Ruby (for Fluentd), Python3 (for downloader), Cron, Supervisor
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
RUN mkdir -p /fluentd/etc /fluentd/downloads /var/log/fluentd \
 && chown -R fluentd:fluentd /fluentd /var/log/fluentd

# Copy configs and scripts
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY fluent.conf /fluentd/etc/fluent.conf
COPY downloader.py /fluentd/etc/downloader.py
COPY fluentd-cron /etc/cron.d/fluentd-cron

# Fix perms
RUN chmod +x /fluentd/etc/downloader.py \
 && chmod 0644 /etc/cron.d/fluentd-cron \
 && crontab /etc/cron.d/fluentd-cron

# Optional: install Python packages if needed
# COPY requirements.txt /fluentd/etc/
# RUN pip3 install --no-cache-dir -r /fluentd/etc/requirements.txt

# Expose Fluentd port
EXPOSE 24224

# Start supervisor (manages fluentd + cron)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf", "-n"]

