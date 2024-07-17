#!/bin/bash

# check if docker deamon is running
if ! docker info >/dev/null 2>&1; then
    echo "...Docker is not running. It will be starting..."
    open --background -a Docker
fi

echo "...stopping all docker containers..."
docker stop $(docker ps -a -q) >/dev/null 2>&1
echo "...all docker containers stopped..."

echo "> Do you wish to remove all docker stuff? (yes or no)"
read yn
if [ $yn == "yes" ]; then
    echo "...removing all docker containers, networks, volumes, and images defined in the docker-compose.yml..."
    docker-compose down --rmi all --volumes --remove-orphans >/dev/null
    echo "...all docker stuff in the current project removed..."
fi
exit
