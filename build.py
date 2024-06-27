#!/usr/bin/env python3

import argparse
import dataclasses
import os
import subprocess


@dataclasses.dataclass
class BuildMetadata:
    dockcross_image: str
    dockcross_version: str


DEFAULT_VERSION = "1.1.0"
DEFAULT_HASH = "0dcb9277b21f916f5646574b9b2229d3b8e97d5e99b935a4d0b7509a5f0ccdcd"
DEFAULT_DOCKCROSS_REGISTRY = "docker.io/dockcross"
# Dockcross image names: https://github.com/dockcross/dockcross?tab=readme-ov-file#summary-cross-compilers
# Debian architectures: https://wiki.debian.org/SupportedArchitectures
BUILD_TARGETS = {
    # "linux-x64": BuildMetadata(dockcross_image="linux-x64", dockcross_version="20240418-88c04a4"),
    # "linux-armv6": BuildMetadata(dockcross_image="linux-armv6", dockcross_version="20240418-88c04a4"),
    "linux-armv6-lts": BuildMetadata(dockcross_image="linux-armv6-lts", dockcross_version="20240418-88c04a4"),
    # "linux-armv7": BuildMetadata(dockcross_image="linux-armv7", dockcross_version="20240418-88c04a4"),
    "linux-armv7-lts": BuildMetadata(dockcross_image="linux-armv7-lts", dockcross_version="20240418-88c04a4"),
    # "linux-arm64": BuildMetadata(dockcross_image="linux-arm64", dockcross_version="20240418-88c04a4"),
    "linux-arm64-lts": BuildMetadata(dockcross_image="linux-arm64-lts", dockcross_version="20240418-88c04a4"),
    "manylinux_2_28-x64": BuildMetadata(dockcross_image="manylinux_2_28-x64", dockcross_version="20240418-88c04a4"),
}


def build_cannelloni(build_metadata: BuildMetadata, build_version: str, build_hash: str, no_build_cache: bool):
    print(f"""
        Build cannelloni for your architecture.

        Dockcross image:    {DEFAULT_DOCKCROSS_REGISTRY}/{build_metadata.dockcross_image}:{build_metadata.dockcross_version}
    """)

    cmd = f"""docker build
        --build-arg CANNELLONI_VERSION={build_version}
        --build-arg CANNELLONI_HASH={build_hash}
        --build-arg DOCKCROSS_REGISTRY={DEFAULT_DOCKCROSS_REGISTRY}
        --build-arg DOCKCROSS_IMAGE={build_metadata.dockcross_image}
        --build-arg DOCKCROSS_VERSION={build_metadata.dockcross_version}
        --output type=local,dest=out ."""

    if no_build_cache:
        print("Disabling docker build cache.")
        cmd += " --no-cache"

    my_env = os.environ.copy()
    my_env["BUILDKIT_PROGRESS"] = "plain"  # show progress output when building with docker
    result = subprocess.run(cmd.split(), env=my_env)
    if result.returncode != 0:
        raise RuntimeError("Failed to build docker image for architecture={}".format(build_metadata.dockcross_image))


def show_version(build_metadata: BuildMetadata):
    print(f"""
Dockcross image    : {DEFAULT_DOCKCROSS_REGISTRY}/{build_metadata.dockcross_image}:{build_metadata.dockcross_version}""")

    cmd = f"""docker run --entrypoint= --rm -v ./show_version.sh:/show_version.sh {DEFAULT_DOCKCROSS_REGISTRY}/{build_metadata.dockcross_image}:{build_metadata.dockcross_version} /show_version.sh""".split()
    result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode == 0:
        print(result.stdout.decode().strip())
    else:
        raise RuntimeError("Failed to build docker image for architecture={}".format(build_metadata.dockcross_image))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Build cannelloni for your architecture')
    parser.add_argument('--architecture', help='Architecture to build.', choices=BUILD_TARGETS.keys(), required=False)
    parser.add_argument('--version', help='Cannelloni release version to build.')
    parser.add_argument('--hash', help='Cannelloni release hash to do integrity check.')
    parser.add_argument('--show', help='Show toolchain versions of dockcross images.', required=False,
                        action='store_true')
    parser.add_argument('--no-cache', help='Disable docker build cache.', required=False, action='store_true')
    args = parser.parse_args()

    given_architecture = args.architecture
    build_version = args.version or DEFAULT_VERSION
    build_hash = args.hash or DEFAULT_HASH
    no_build_cache = args.no_cache

    if given_architecture is None:
        target_list = list(BUILD_TARGETS.keys())
    else:
        target_list = [given_architecture]

    for architecture in target_list:
        metadata = BUILD_TARGETS[architecture]

        if args.show:
            show_version(metadata)
        else:
            build_cannelloni(metadata, build_version, build_hash, no_build_cache)
