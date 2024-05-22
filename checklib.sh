#!/usr/bin/env bash
set -x

# for other architectures than x86_64, copy libraries to this location for cmake toolchain
TARGET_XCC_DIR="$(ls -d /usr/xcc/*/*/sysroot/)"

if [ -n "$TARGET_XCC_DIR" ]; then
  echo "Built with crosstool-ng"
  "$TARGET_XCC_DIR"/usr/bin/ldd --version
  echo -e "\nPrint shared object information on cannelloni library:"
  readelf -h /tmp/cannelloni/cannelloni
else
  echo "Not a cross build."
  ldd --version
  ldd /tmp/cannelloni/cannelloni
fi
