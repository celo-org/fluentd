# Use the official Fluentd Debian image
FROM fluent/fluentd:v1.19.0-debian

# Switch to root to install system packages and gems
USER root
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-venv \
    cron \
    supervisor \
 && gem install fluent-plugin-gcloud-pubsub --no-document \
 && rm -rf /var/lib/apt/lists/*

# Create a Python virtual environment
RUN python3 -m venv /opt/venv

# Activate the virtual environment and install Python packages
ENV PATH="/opt/venv/bin:$PATH"
RUN pip3 install --no-cache-dir google-cloud-storage

# Switch back to the fluent user for subsequent commands and runtime
USER fluent

# The official image already sets up the fluentd user and directories
# with correct permissions, but we will make sure our directories are correct.
RUN mkdir -p /fluentd/etc /fluentd/log /var/log/fluentd

# Copy your configurations
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY fluent.conf /fluentd/etc/fluent.conf
COPY downloader.py /fluentd/etc/downloader.py
COPY fluentd-cron /etc/cron.d/fluentd-cron

# Fix permissions
RUN chmod +x /fluentd/etc/downloader.py \
 && chmod 0644 /etc/cron.d/fluentd-cron

# Expose Fluentd port
EXPOSE 24224

# The base image's entrypoint is fluentd, but you are using supervisor.
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf", "-n"]
