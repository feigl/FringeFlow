#!/bin/bash



# https://hub.docker.com/r/mobigroup/pygmtsar

docker buildx create --name mobigroup
docker buildx use mobigroup
docker buildx inspect --bootstrap
docker buildx build . -f pygmtsar.Dockerfile \
    --platform linux/amd64,linux/arm64 \
    --tag mobigroup/pygmtsar:2022-11-12 \
    --tag mobigroup/pygmtsar:latest \
    --pull --push --no-cache