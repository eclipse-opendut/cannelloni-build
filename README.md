# Cross compile cannelloni

CI pipeline to build [cannelloni](https://github.com/mguentner/cannelloni) for multiple architectures.
Uses [dockcross](https://github.com/dockcross/dockcross) to compile for the specified architectures.

* Configured architectures are:
  * [manylinux_2_28-x64](https://hub.docker.com/r/dockcross/manylinux_2_28-x64), **x86_64** for regular desktop (does not require cross, uses glibc 2.28)
  * [linux-armv6-lts](https://hub.docker.com/r/dockcross/linux-armv6-lts), for e.g. Raspberry Pi 3 with good old Raspbian, arm-linux-gnueabihf, armhf, glibc 2.28
  * [linux-armv7-lts](https://hub.docker.com/r/dockcross/linux-armv7-lts), **armv7**
  * [linux-arm64-lts](https://hub.docker.com/r/dockcross/linux-arm64-lts), **arm64** for e.g. Yocto Linux


## Build for multiple architectures

If building with podman, it requires at least version 4.1 (requires the output flag implemented [here](https://github.com/containers/buildah/pull/3823)).
Run `python build.py` to build for all architectures.

### Description of build workflow

The build workflow is run in docker containers (dockcross).
1. Build libsctp 
    * Build in temporary directory `LIBSCTP_BUILD_DIR=/tmp/libsctp_build/`
    * Copy libraries and headers to cannelloni build directory `CANNELLONI_BUILD_DIR=/tmp/cannelloni_build/`
    * Copy release artifacts to target directory `TARGET_DIR=/tmp/cannelloni`
    * Add notes about source code origin to `${TARGET_DIR}/SOURCES.md`
2. Build cannelloni
    * Build in temporary directory `CANNELLONI_BUILD_DIR=/tmp/cannelloni_build/`
    * Copy release artifacts to `TARGET_DIR=/tmp/cannelloni`
    * Add notes about source code origin to `${TARGET_DIR}/SOURCES.md`
3. Bundle files from `TARGET_DIR` into final release artifact. 
4. Separate docker build stage is used to collect the final release artifact

## Install cannelloni

* Download appropriate architecture.
  ```shell
  wget https://github.com/eclipse-opendut/cannelloni-build/releases/download/v1.1.0/cannelloni_linux-x64_1.1.0.tar.gz -O /tmp/cannelloni.tar.gz
  cd /tmp
  tar xf cannelloni.tar.gz
  ```
* The archive comes with a matching `libsctp` included.
* Extract archive on your target system and copy to system location: 
  ```shell
  cp cannelloni/libcannelloni-common.so.0 /lib/
  cp cannelloni/cannelloni /usr/local/bin/
  cannelloni  # run cannelloni
  ```
* Or copy to custom location:
  ```shell
  sudo cp /tmp/cannelloni/ /opt/cannelloni
  export LD_LIBRARY_PATH="/opt/cannelloni/:$LD_LIBRARY_PATH"
  export PATH="/opt/cannelloni:$PATH"
  cannelloni  # run cannelloni
  ```

## Update version

* Download new version and determine hash:
  ```shell
  wget https://github.com/mguentner/cannelloni/archive/refs/tags/v1.1.0.tar.gz -O cannelloni-1.1.0.tar.gz
  sha256sum cannelloni-1.1.0.tar.gz
  ```
* Update version and hash in [build script](build.py).
* Set new git tag
  ```shell
  git tag v1.1.0
  git push origin tag v1.1.0 
  ```
## Add another architecture

* Check for available version at [docker-cross](https://github.com/dockcross/dockcross).
* Update variable `ALL_ARCHITECTURES` in [build script](build.py).


## Check your architecture

* System information on e.g. your Raspberry Pi:
```shell
uname --all           # print system information (kernel version, processor type)
uname --machine       # print machine hardware information
strings /lib/arm-linux-gnueabihf/libc.so.6 | grep GLIBC_
strings /lib/*/libc.so.6 | grep GLIBC_
ldd --version         # GLIBC version
gcc -v                # GCC version
gcc -print-multiarch  # print target triple

```

* Check binary and shared object files
```shell
# ldd - print shared object dependencies
ldd ./cannelloni
ldd ./libcannelloni-common.so.0
# readelf - display information about ELF files
readelf -h libcannelloni-common.so.0
```
