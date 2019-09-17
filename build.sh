#!/bin/bash

set -ex

IMAGE=zilliqa-docker

if [ "$#" -lt 1 ]; then
    docker build -t $IMAGE .
else
    docker build --build-arg "ZILLIQA_VERSION=$1" --build-arg "FORCE_UPDATE=no$2" -t "$IMAGE:$1" .
fi

