#!/bin/bash

# default version, hash
VERSION="${VERSION:-1.1.0}"
HASH="${HASH:-0dcb9277b21f916f5646574b9b2229d3b8e97d5e99b935a4d0b7509a5f0ccdcd}"
ALL_ARCHITECTURES="linux-arm64 linux-x64 linux-armv7"

if [ -z "$VERSION" ]; then
  echo "Could not find environment variable VERSION!"
  exit 1
fi

if [ -z "$HASH" ]; then
  echo "Could not find environment variable HASH!"
  exit 1
fi

for ARCHITECTURE in $ALL_ARCHITECTURES; do
  docker build \
    --build-arg VERSION="$VERSION" \
    --build-arg HASH="$HASH" \
    --build-arg ARCHITECTURE="$ARCHITECTURE" \
    --output type=local,dest=out .
done
