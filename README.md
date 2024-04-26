# Cross compile cannelloni

CI pipeline to build [cannelloni](https://github.com/mguentner/cannelloni) for multiple architectures.
Uses [dockcross](https://github.com/dockcross/dockcross) to compile for the specified architectures.

* Configured architectures are:
  * [linux-arm64](https://hub.docker.com/r/dockcross/linux-arm64), **arm64** for e.g. Yocto Linux
  * [linux-x64](https://hub.docker.com/r/dockcross/linux-x64), **x86_64** for regular desktop (does not require cross)
  * [linux-armv7](https://hub.docker.com/r/dockcross/linux-armv7), **armv7** for e.g. Raspberry Pi 3


## Build for multiple architectures

Run `build.sh` to build for all architectures.

## Install cannelloni

* Download appropriate architecture.
* Extract archive on your target system and copy to system location: 
  ```shell
  cp libcannelloni-common.so.0 /usr/local/lib/
  cp cannelloni /usr/local/bin/
  ```

## Update version

* Download new version and determine hash:
  ```shell
  wget https://github.com/mguentner/cannelloni/archive/refs/tags/v1.1.0.tar.gz -O cannelloni-1.1.0.tar.gz
  sha256sum cannelloni-1.1.0.tar.gz
  ```
* Update version and hash in [build script](build.sh).
* Set new git tag
  ```shell
  git tag v1.1.0
  git push origin tag v1.1.0 
  ```
## Add another architecture

* Check for available version at [docker-cross](https://github.com/dockcross/dockcross).
* Update variable `ALL_ARCHITECTURES` in [build script](build.sh).
