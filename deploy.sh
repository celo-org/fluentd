#!/bin/bash

# Define the volume name and image name
VOLUME_NAME="fluentd_log_volume"
IMAGE_NAME="fluentd-gcp:1.0.0"

# Check if the volume exists, and create it if it doesn't
if [ ! "$(docker volume ls -q -f name=$VOLUME_NAME)" ]; then
    echo "Creating Docker volume: $VOLUME_NAME"
    docker volume create $VOLUME_NAME
fi

# Stop and remove any old container
docker stop fluentd-container >/dev/null 2>&1 || true
docker rm fluentd-container >/dev/null 2>&1 || true

# Run the container with the named volume
echo "Running the container..."
docker run \
  --name fluentd-container \
  -d \
  -v $VOLUME_NAME:/fluentd/log \
  $IMAGE_NAME
