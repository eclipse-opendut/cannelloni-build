#!/bin/bash

TARGET_XCC_DIR="$(ls -d /usr/xcc/*/*/sysroot/ 2>/dev/null)"
TARGET_TRIPLE="$(ls /usr/xcc/)"
if [ -n "$TARGET_XCC_DIR" ]; then
  LDD_VERSION="$("$TARGET_XCC_DIR"/usr/bin/ldd --version | head -n1)"
else
  LDD_VERSION="$(ldd --version | head -n1)"
  TARGET_TRIPLE="$(gcc -print-multiarch)"
fi

echo "Glibc version      : $LDD_VERSION"
echo "Target triple      : $TARGET_TRIPLE"
