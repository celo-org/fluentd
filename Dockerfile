# Use the official Fluentd Debian image
FROM fluent/fluentd:v1.19.0-debian

# Switch to root to install system packages and gems
USER root

# Install system dependencies:
# - python3-pip and python3-venv for the Python script
# - cron and supervisor for managing the processes
# - gem install ensures the gcloud-pubsub plugin is installed and updated
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-venv \
    cron \
    supervisor \
 && gem install fluent-plugin-gcloud-pubsub --no-document \
 && rm -rf /var/lib/apt/lists/*

# Create the /var/log/fluentd directory as root, as it requires elevated permissions
RUN mkdir -p /var/log/fluentd

# Create a Python virtual environment
RUN python3 -m venv /opt/venv

# Activate the virtual environment and install Python packages
ENV PATH="/opt/venv/bin:$PATH"
RUN pip3 install --no-cache-dir google-cloud-storage

# Switch back to the fluent user for all subsequent commands and runtime
USER fluent

# The official image already sets up the /fluentd directory, but we can confirm it exists
RUN mkdir -p /fluentd/etc /fluentd/log

# Copy your configurations
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY fluent.conf /fluentd/etc/fluent.conf
COPY downloader.py /fluentd/etc/downloader.py
COPY fluentd-cron /etc/cron.d/fluentd-cron

# Fix permissions for the scripts
RUN chmod +x /fluentd/etc/downloader.py \
 && chmod 0644 /etc/cron.d/fluentd-cron

# Expose Fluentd port
EXPOSE 24224

# The base image's entrypoint is fluentd, but you are using supervisor.
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf", "-n"]
