# Use the official Fluentd Debian image
FROM fluent/fluentd:v1.19.0-debian

# Switch to root to perform all system-level installations and file operations
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-venv \
    cron \
    supervisor \
 && gem install fluent-plugin-gcloud-pubsub --no-document \
 && rm -rf /var/lib/apt/lists/*

# Create all necessary directories as root
RUN mkdir -p /var/log/supervisor /var/log/fluentd /fluentd/etc /fluentd/log /fluentd/cron

# Create a Python virtual environment as root
RUN python3 -m venv /opt/venv

# Activate the virtual environment and install Python packages
ENV PATH="/opt/venv/bin:$PATH"
RUN pip3 install --no-cache-dir google-cloud-storage

# Copy all configurations and scripts as root
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY fluent.conf /fluentd/etc/fluent.conf
COPY downloader.py /fluentd/etc/downloader.py
COPY fluentd-cron /etc/cron.d/fluentd-cron
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Set correct permissions and ownership for all files and directories
RUN chmod +x /fluentd/etc/downloader.py \
 && chmod 0644 /etc/cron.d/fluentd-cron \
 && chmod +x /usr/local/bin/docker-entrypoint.sh \
 && chown -R 1000:1000 /fluentd /var/log/fluentd /var/log/supervisor /var/run/supervisor

# Switch to the fluent user for runtime, as all setup is complete
USER fluent

# Expose Fluentd port
EXPOSE 24224

# Set the entry point and the command.
# The entry point will run the permissions script.
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf", "-n"]
