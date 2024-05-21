#!/usr/bin/env python3

import argparse
import subprocess

DEFAULT_VERSION = "1.1.0"
DEFAULT_HASH = "0dcb9277b21f916f5646574b9b2229d3b8e97d5e99b935a4d0b7509a5f0ccdcd"
ALL_ARCHITECTURES = ["linux-arm64", "linux-x64", "linux-armv7"]

DEBIAN_ARCHITECTURES = {
    "linux-arm64": "arm64",
    "linux-x64": "amd64",
    "linux-armv7": "armhf",
}


def build_cannelloni(architecture: str, build_version: str, build_hash: str):
    debian_architecture = DEBIAN_ARCHITECTURES[architecture]

    cmd = f"""docker build
        --build-arg VERSION={build_version}
        --build-arg HASH={build_hash}
        --build-arg ARCHITECTURE={architecture}
        --build-arg DEBIAN_ARCHITECTURE={debian_architecture}
        --output type=local,dest=out ."""

    result = subprocess.run(cmd.split())
    if result.returncode != 0:
        raise RuntimeError("Failed to build docker image for architecture={}".format(architecture))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Build cannelloni for your architecture')
    parser.add_argument('--architecture', help='Architecture to build.', choices=ALL_ARCHITECTURES, required=False)
    parser.add_argument('--version', help='Cannelloni release version to build.')
    parser.add_argument('--hash', help='Cannelloni release hash to do integrity check.')
    args = parser.parse_args()

    given_architecture = args.architecture
    build_version = args.version or DEFAULT_VERSION
    build_hash = args.hash or DEFAULT_HASH

    if given_architecture is None:
        build_architectures = ALL_ARCHITECTURES
    else:
        build_architectures = [given_architecture]
    print(build_architectures)
    print(build_version)
    print(build_hash)

    for architecture in build_architectures:
        build_cannelloni(architecture, build_version, build_hash)
