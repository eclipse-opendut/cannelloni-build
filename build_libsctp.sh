#!/usr/bin/env bash
set -x
set -e

LIBSCTP_VERSION="${LIBSCTP_VERSION:-1.0.19}"
LIBSCTP_HASH="${LIBSCTP_HASH:-9251b1368472fb55aaeafe4787131bdde4e96758f6170620bc75b638449cef01}"

if [ -z "$LIBSCTP_VERSION" ]; then
  echo "No library version for libsctp specified! Set environment variable 'LIBSCTP_VERSION'!"
  exit 1
fi

# for other architectures than x86_64, copy libraries to this location for cmake toolchain
set +e
TARGET_XCC_DIR="$(ls -d /usr/xcc/*/*/sysroot/)"
TARGET_TRIPLE="$(ls /usr/xcc/)"
set -e

wget https://github.com/sctp/lksctp-tools/archive/refs/tags/v"$LIBSCTP_VERSION".tar.gz -O libsctp-"$LIBSCTP_VERSION".tar.gz
echo "$LIBSCTP_HASH libsctp-$LIBSCTP_VERSION.tar.gz" | sha256sum --check --status

tar --strip-components=1 -xvf libsctp-"$LIBSCTP_VERSION".tar.gz
./bootstrap

# CFLAGS are set to "MinSizeRel"
export CFLAGS="-Os -DNDEBUG"
# CFLAGS are set to "Release"
export CFLAGS="-O3 -DNDEBUG"
if [ -n "$TARGET_TRIPLE" ]; then
  ./configure --host "$TARGET_TRIPLE"
else
  ./configure
fi
make

# show location of the following files for debug purposes
find . -name "libsctp*"
find . -name "sctp.h"

if [ -n "$TARGET_XCC_DIR" ]; then
  cp ./src/include/netinet/sctp.h "$TARGET_XCC_DIR"/usr/include/netinet/
  cp src/lib/.libs/libsctp.* "$TARGET_XCC_DIR"/usr/lib/
else
  echo "Not a cross build. Nothing to do for current architecture: $ARCHITECTURE"
  cp ./src/include/netinet/sctp.h /usr/include/netinet/
  cp src/lib/.libs/libsctp.* /usr/lib/
fi

cp -a ./src/include/netinet/ /tmp/cannelloni/
cp --no-dereference --preserve=links src/lib/.libs/libsctp.* /tmp/cannelloni/
