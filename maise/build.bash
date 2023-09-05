#!/usr/bin/env bash
# Helper script for building & uploading the MAISE image
set -e
set -u
set -o pipefail

#DOCKERHUB_USERNAME=nbearson
#DOCKERHUB_USERNAME=feigl
DOCKERHUB_USERNAME=$USER
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

DATETAG=$(date +"%Y%m%d")

#docker build -t docker.io/$DOCKERHUB_USERNAME/maise:latest -f Dockerfile $SCRIPT_DIR
#docker build -t docker.io/$DOCKERHUB_USERNAME/maise:latest -f DockerfileKF $SCRIPT_DIR
#docker build -t docker.io/$DOCKERHUB_USERNAME/maise:latest -f Dockerfile20230615 $SCRIPT_DIR
#docker build -t docker.io/$DOCKERHUB_USERNAME/maise:latest -f Dockerfile20230815 $SCRIPT_DIR
docker build -t docker.io/$DOCKERHUB_USERNAME/maise:20230905 -f Dockerfile20230905 $SCRIPT_DIR
echo "docker.io/$DOCKERHUB_USERNAME/maise:latest was built successfully."

echo "The following commands are only being printed for your convenience:"

echo "docker push docker.io/$DOCKERHUB_USERNAME/maise:latest"

echo "docker tag docker.io/$DOCKERHUB_USERNAME/maise:latest docker.io/$DOCKERHUB_USERNAME/maise:$DATETAG"
echo "docker push docker.io/$DOCKERHUB_USERNAME/maise:$DATETAG"

# if you see errors about no space left on device, then try the following command
# docker system prune -a -f