#!/bin/bash

# Get the image name from the deploy.sh script
IMAGE_NAME=$(grep "IMAGE_NAME" deploy.sh | head -n 1 | cut -d'"' -f2)

# Build the Docker image
echo "Building image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .
