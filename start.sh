#!/bin/bash

# check if docker deamon is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. It will be starting..."
    open --background -a Docker
fi

# compose up with cache refresh and detached mode
docker-compose up --build -d