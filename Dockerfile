ARG DOCKCROSS_REGISTRY=docker.io/dockcross
ARG DOCKCROSS_IMAGE=linux-arm64
ARG DOCKCROSS_VERSION=latest

FROM $DOCKCROSS_REGISTRY/$DOCKCROSS_IMAGE:$DOCKCROSS_VERSION as cannelloni-builder
# Version arguments that may be controlled via docker build argument
ARG CANNELLONI_VERSION=1.1.0
ARG CANNELLONI_HASH=0dcb9277b21f916f5646574b9b2229d3b8e97d5e99b935a4d0b7509a5f0ccdcd

# Output definitions
ENV TARGET_DIR=/tmp/cannelloni
ENV CANNELLONI_BUILD_LOG=$TARGET_DIR/build-metadata-log.txt
RUN mkdir $TARGET_DIR

# Document docker build log arguments
ARG DOCKCROSS_REGISTRY=docker.io/dockcross
ARG DOCKCROSS_IMAGE=linux-arm64
ARG DOCKCROSS_VERSION=latest
RUN echo -e "Built with $DOCKCROSS_REGISTRY/$DOCKCROSS_IMAGE:$DOCKCROSS_VERSION\n" | tee -a ${CANNELLONI_BUILD_LOG}

# Version definitions
ENV CANNELLONI_VERSION=$CANNELLONI_VERSION
ENV CANNELLONI_HASH=$CANNELLONI_HASH
ENV LIBSCTP_VERSION=1.0.19
ENV LIBSCTP_HASH=9251b1368472fb55aaeafe4787131bdde4e96758f6170620bc75b638449cef01

# Build libsctp
ENV CANNELLONI_BUILD_DIR=/tmp/cannelloni_build/
ENV LIBSCTP_BUILD_DIR=/tmp/libsctp_build/
WORKDIR $LIBSCTP_BUILD_DIR
COPY build_libsctp.sh /build_libsctp.sh
# https://github.com/docker/docs/blob/da4ccc81e6b1bbd585c9f5ac9a35b9c8684c5d57/content/build/building/best-practices.md#using-pipes
# If you want the command to fail due to an error at any stage in the pipe, prepend set -o pipefail && to ensure that an unexpected error prevents the build from inadvertently succeeding. For example:
RUN ["/bin/bash", "-c", "set -o pipefail && /build_libsctp.sh | tee -a ${CANNELLONI_BUILD_LOG}"]

# Build cannelloni
WORKDIR $CANNELLONI_BUILD_DIR
COPY build_cannelloni.sh /build_cannelloni.sh
RUN ["/bin/bash", "-c", "set -o pipefail && /build_cannelloni.sh | tee -a ${CANNELLONI_BUILD_LOG}"]

# Bundle result files: create tar file as output
WORKDIR /tmp/
RUN find $TARGET_DIR
RUN tar cf /tmp/cannelloni.tar.gz cannelloni/*

# Separate build stage, all files in this stage are added to the final output
FROM scratch AS export-stage
ARG DOCKCROSS_IMAGE=linux-arm64
ARG VERSION=1.1.0

# copy tar file from builder
COPY --from=cannelloni-builder /tmp/cannelloni.tar.gz /cannelloni_${DOCKCROSS_IMAGE}_${VERSION}.tar.gz
