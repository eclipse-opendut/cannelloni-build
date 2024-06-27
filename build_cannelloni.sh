#!/bin/bash
set -x
set -e

############################################
# CONFIG
############################################
# assumes to be run in a temporary directory
VERSION="${CANNELLONI_VERSION:-1.1.0}"
HASH="${CANNELLONI_HASH:-0dcb9277b21f916f5646574b9b2229d3b8e97d5e99b935a4d0b7509a5f0ccdcd}"
TARGET_DIR="${TARGET_DIR:-/tmp/cannelloni}"
DOWNLOAD_URL="https://github.com/mguentner/cannelloni/archive/refs/tags/v${VERSION}.tar.gz"

# Download source code
wget "$DOWNLOAD_URL" -O "cannelloni-$VERSION.tar.gz"
echo "$HASH cannelloni-$VERSION.tar.gz" | sha256sum --check --status

# Extract archive
tar --strip-components=1 -xvf "cannelloni-$VERSION.tar.gz"

# Check if libsctp is at the expected location
if [ ! -e "netinet/sctp.h" ]; then
  echo "Could not find sctp header file! Aborting."
  exit 1
fi
if [ ! -e "libsctp.so.1" ]; then
  echo "Could not find sctp library file! Aborting."
  exit 1
fi

############################################
# Build cannelloni
############################################
cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DSCTP_INCLUDE_DIR=./netinet/ -DSCTP_LIBRARY=./ -DSCTP_SUPPORT=ON 2>&1
make 2>&1

echo Finished building cannelloni

############################################
# COPY results to target directory
############################################
mkdir -p "${TARGET_DIR}/sources/"
cp --remove-destination libcannelloni-common.so.0.0.1 "${TARGET_DIR}"/libcannelloni-common.so.0
cp cannelloni "${TARGET_DIR}"/cannelloni
cp cannelloni-"$VERSION".tar.gz "${TARGET_DIR}"/sources/
mv gpl-2.0.txt "${TARGET_DIR}"/cannelloni-license-gpl-2.0.txt
echo "You can find a copy of the cannelloni source code attached to this archive." >> "${TARGET_DIR}/SOURCES.md"
echo "The cannelloni source code was downloaded from here: $DOWNLOAD_URL." >> "${TARGET_DIR}/SOURCES.md"

############################################
# CHECK result
############################################
# for other architectures than x86_64, copy libraries to this location for cmake toolchain
TARGET_XCC_DIR="$(ls -d /usr/xcc/*/*/sysroot/ 2>/dev/null || echo)"

if [ -n "$TARGET_XCC_DIR" ]; then
  echo "Built with crosstool-ng"
  "$TARGET_XCC_DIR"/usr/bin/ldd --version
  echo -e "\nPrint shared object information on cannelloni library:"
  readelf -h "${TARGET_DIR}"/cannelloni
else
  echo "Not a cross build."
  ldd --version
  ldd "${TARGET_DIR}"/cannelloni
fi
