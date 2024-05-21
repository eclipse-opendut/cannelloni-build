#!/usr/bin/env bash
set -x

# for other architectures than x86_64, copy libraries to this location for cmake toolchain
TARGET_XCC_DIR="$(ls -d /usr/xcc/*/*/sysroot/)"

if [ -n "$TARGET_XCC_DIR" ]; then
  cp /usr/include/netinet/sctp.h "$TARGET_XCC_DIR"/usr/include/netinet/
  cp /usr/lib/*/libsctp.* "$TARGET_XCC_DIR"/usr/lib/
else
  echo "Nothing to do for current architecture: $ARCHITECTURE"
fi
