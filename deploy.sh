#!/bin/bash

# Define the volume name and image name
IMAGE_NAME="fluentd"
CONTAINER_NAME="fluentd-container"
LOG_DIR_PATH="$(pwd)/log"

# Stop and remove any existing container
docker stop $CONTAINER_NAME >/dev/null 2>&1 || true
docker rm $CONTAINER_NAME >/dev/null 2>&1 || true

# Change the ownership of the log directory to match the fluent user (UID 1000)
# This must be done on the host before the container is run
if [ ! -d "$LOG_DIR_PATH" ]; then
    mkdir -p "$LOG_DIR_PATH"
    sudo chown -R 1000:1000 "$LOG_DIR_PATH"
else
    sudo chown -R 1000:1000 "$LOG_DIR_PATH"
fi

# Run the container
echo "Running the container..."
docker run \
  --name $CONTAINER_NAME \
  -d \
  -v "$LOG_DIR_PATH":/fluentd/log \
  $IMAGE_NAME
