#!/usr/bin/env python3

import argparse
import dataclasses
import os
import subprocess


@dataclasses.dataclass
class BuildMetadata:
    debian_architecture: str
    dockcross_image: str
    dockcross_version: str


DEFAULT_VERSION = "1.1.0"
DEFAULT_HASH = "0dcb9277b21f916f5646574b9b2229d3b8e97d5e99b935a4d0b7509a5f0ccdcd"
# Dockcross image names: https://github.com/dockcross/dockcross?tab=readme-ov-file#summary-cross-compilers
# Debian architectures: https://wiki.debian.org/SupportedArchitectures
BUILD_TARGETS = {
    "linux-arm64": BuildMetadata(debian_architecture="arm64", dockcross_image="linux-arm64", dockcross_version="20240418-88c04a4"),
    "linux-x64": BuildMetadata(debian_architecture="amd64", dockcross_image="linux-x64", dockcross_version="20240418-88c04a4"),
    "linux-armv7": BuildMetadata(debian_architecture="armhf", dockcross_image="linux-armv7", dockcross_version="20240418-88c04a4"),
    "linux-armv7-lts": BuildMetadata(debian_architecture="armhf", dockcross_image="linux-armv7-lts", dockcross_version="20240418-88c04a4"),
    "linux-armv6": BuildMetadata(debian_architecture="armhf", dockcross_image="linux-armv6", dockcross_version="20240418-88c04a4"),
    "linux-armv6-lts": BuildMetadata(debian_architecture="armhf", dockcross_image="linux-armv6-lts", dockcross_version="20240418-88c04a4"),
}


def build_cannelloni(target: BuildMetadata, build_version: str, build_hash: str):
    cmd = f"""docker build
        --build-arg VERSION={build_version}
        --build-arg HASH={build_hash}
        --build-arg DOCKCROSS_IMAGE={target.dockcross_image}
        --build-arg DOCKCROSS_VERSION={target.dockcross_version}
        --build-arg DEBIAN_ARCHITECTURE={target.debian_architecture}
        --output type=local,dest=out ."""

    my_env = os.environ.copy()
    my_env["BUILDKIT_PROGRESS"] = "plain"  # show progress output when building with docker
    result = subprocess.run(cmd.split(), env=my_env)
    if result.returncode != 0:
        raise RuntimeError("Failed to build docker image for architecture={}".format(target.debian_architecture))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Build cannelloni for your architecture')
    parser.add_argument('--architecture', help='Architecture to build.', choices=BUILD_TARGETS.keys(), required=False)
    parser.add_argument('--version', help='Cannelloni release version to build.')
    parser.add_argument('--hash', help='Cannelloni release hash to do integrity check.')
    args = parser.parse_args()

    given_architecture = args.architecture
    build_version = args.version or DEFAULT_VERSION
    build_hash = args.hash or DEFAULT_HASH

    if given_architecture is None:
        target_list = list(BUILD_TARGETS.keys())
    else:
        target_list = [given_architecture]

    for architecture in target_list:
        metadata = BUILD_TARGETS[architecture]

        print(f"""
            Build cannelloni for your architecture.
            
            Dockcross image:    dockcross/{metadata.dockcross_image}:{metadata.dockcross_version}
            Debian architecture:       {metadata.debian_architecture}
        """)
        build_cannelloni(metadata, build_version, build_hash)
