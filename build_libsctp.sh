#!/usr/bin/env bash
set -x
set -e

############################################
# CONFIG
############################################
# assumes to be run in a temporary directory
# has outputs that are added to the build directory of cannelloni!

LIBSCTP_VERSION="${LIBSCTP_VERSION:-1.0.19}"
LIBSCTP_HASH="${LIBSCTP_HASH:-9251b1368472fb55aaeafe4787131bdde4e96758f6170620bc75b638449cef01}"
TARGET_DIR="${TARGET_DIR:-/tmp/target}"
CANNELLONI_BUILD_DIR="${CANNELLONI_BUILD_DIR:-/tmp/cannelloni_build}"
DOWNLOAD_URL="https://github.com/sctp/lksctp-tools/archive/refs/tags/v${LIBSCTP_VERSION}.tar.gz"

############################################
# Check if environment variable is present
if [ -z "$LIBSCTP_VERSION" ]; then
  echo "No library version for libsctp specified! Set environment variable 'LIBSCTP_VERSION'!"
  exit 1
fi

# for other architectures than x86_64, copy libraries to this location for cmake toolchain
set +e
TARGET_XCC_DIR="$(ls -d /usr/xcc/*/*/sysroot/)"
TARGET_TRIPLE="$(ls /usr/xcc/)"
set -e

wget "$DOWNLOAD_URL" -O libsctp-"$LIBSCTP_VERSION".tar.gz
echo "$LIBSCTP_HASH libsctp-$LIBSCTP_VERSION.tar.gz" | sha256sum --check --status

tar --strip-components=1 -xvf libsctp-"$LIBSCTP_VERSION".tar.gz
./bootstrap

############################################
# Build libsctp
############################################
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

# Copy library and its headers to a location where the compiler will find it
if [ -n "$TARGET_XCC_DIR" ]; then
  cp ./src/include/netinet/sctp.h "$TARGET_XCC_DIR"/usr/include/netinet/
  cp src/lib/.libs/libsctp.* "$TARGET_XCC_DIR"/usr/lib/
else
  echo "Not a cross build. Architecture: $ARCHITECTURE"
  cp ./src/include/netinet/sctp.h /usr/include/netinet/
  cp src/lib/.libs/libsctp.* /usr/lib/
fi

############################################
# COPY results to cannelloni build directory
############################################
mkdir -p "${CANNELLONI_BUILD_DIR}"
# copy header files
cp -a ./src/include/netinet/ "${CANNELLONI_BUILD_DIR}"/
# copy object files
cp --no-dereference --preserve=links src/lib/.libs/libsctp.{a,so*} "${CANNELLONI_BUILD_DIR}"/

############################################
# COPY results to target directory
############################################
# copy source code
mkdir -p "${TARGET_DIR}/sources/"
cp libsctp-"$LIBSCTP_VERSION".tar.gz "${TARGET_DIR}/sources/"
# copy license
cp COPYING.lib "${TARGET_DIR}/libsctp-license.txt"
# copy library files
cp --no-dereference --preserve=links src/lib/.libs/libsctp.{a,so*} "${TARGET_DIR}"/

echo "You can find a copy of the libsctp source code attached to this archive." >> "${TARGET_DIR}/SOURCES.md"
echo "The libsctp source code was downloaded from here: $DOWNLOAD_URL" >> "${TARGET_DIR}/SOURCES.md"
