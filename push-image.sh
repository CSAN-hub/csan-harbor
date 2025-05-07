#!/bin/bash

# Push a container image to Harbor

# @author  Fabrice Jammes

set -euxo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

. $DIR/conf.sh

image="alpine:latest"

# Check if podman is installed
if ! command -v podman &> /dev/null
then
    echo "podman could not be found and will be installed"
    sudo apt install -y skopeo
fi

skopeo login --tls-verify=false --username="$harbor_username" \
    --password="$harbor_password" \
    $harbor_domain/library

skopeo sync --dest-tls-verify=false --src docker  --dest docker --scoped "$image" $harbor_domain/library

skopeo inspect --tls-verify=false  docker://$harbor_domain/library/docker.io/library/alpine:latest
