ARG DOCKCROSS_IMAGE=linux-arm64
ARG DOCKCROSS_VERSION=latest

FROM dockcross/$DOCKCROSS_IMAGE:$DOCKCROSS_VERSION as cannelloni-builder
ARG VERSION=1.1.0
ARG HASH=0dcb9277b21f916f5646574b9b2229d3b8e97d5e99b935a4d0b7509a5f0ccdcd
ARG DOCKCROSS_IMAGE=linux-arm64
ARG DOCKCROSS_VERSION=latest

RUN mkdir /tmp/cannelloni

ENV LIBSCTP_VERSION=1.0.19
WORKDIR /tmp/libsctp
# copy installed libraries to expected target location for cmake toolchain
COPY build_libsctp.sh /build_libsctp.sh
RUN /build_libsctp.sh

WORKDIR /tmp/cannelloni
RUN wget https://github.com/mguentner/cannelloni/archive/refs/tags/v$VERSION.tar.gz -O cannelloni-$VERSION.tar.gz
RUN echo "$HASH cannelloni-$VERSION.tar.gz" | sha256sum --check --status
RUN tar --strip-components=1 -xvf cannelloni-$VERSION.tar.gz

# Document build metadata
RUN echo "Built with dockcross/$DOCKCROSS_IMAGE:$DOCKCROSS_VERSION\n" | tee -a /tmp/cannelloni/build-metadata.txt

RUN cmake -DCMAKE_BUILD_TYPE=MinSizeRel -DSCTP_INCLUDE_DIR=/tmp/libsctp/src/include/netinet/ -DSCTP_LIBRARY=/tmp/libsctp/src/lib/.libs/ -DSCTP_SUPPORT=ON 2>&1 | tee -a /tmp/cannelloni/build-metadata.txt
RUN make 2>&1 | tee -a /tmp/cannelloni/build-metadata.txt

COPY checklib.sh /checklib.sh
RUN /checklib.sh 2>&1 | tee -a /tmp/cannelloni/build-metadata.txt

WORKDIR /tmp/

# rename libcannelloni in target directory
RUN cp --remove-destination /tmp/cannelloni/libcannelloni-common.so.0.0.1 /tmp/cannelloni/libcannelloni-common.so.0
RUN mv cannelloni/gpl-2.0.txt cannelloni/cannelloni-license-gpl-2.0.txt
# copy libsctp license to target directory
RUN curl https://raw.githubusercontent.com/sctp/lksctp-tools/master/COPYING.lib --output /tmp/cannelloni/libsctp-license.txt
# add note about source
RUN echo "You can find a copy of the cannelloni source code at: https://github.com/mguentner/cannelloni/archive/refs/tags/v$VERSION.tar.gz" > /tmp/cannelloni/SOURCES.md
RUN echo "You can find a copy of the libsctp source and license here: https://github.com/sctp/lksctp-tools" >> /tmp/cannelloni/SOURCES.md

# create tar file as output
RUN tar cf /tmp/cannelloni.tar.gz \
    cannelloni/SOURCES.md \
    cannelloni/cannelloni cannelloni/libcannelloni-common.so.0 cannelloni/cannelloni-license-gpl-2.0.txt cannelloni/README.md \
    cannelloni/build-metadata.txt \
    cannelloni/libsctp-license.txt cannelloni/libsctp*.so*

# create directory as output
# RUN mkdir -p /cannelloni_${DOCKCROSS_IMAGE}_${VERSION}/
# RUN cp /tmp/cannelloni/libcannelloni-common.so.0 /tmp/cannelloni/cannelloni /tmp/cannelloni/README.md /tmp/cannelloni/gpl-2.0.txt /cannelloni_${DOCKCROSS_IMAGE}_${VERSION}/

FROM scratch AS export-stage
ARG DOCKCROSS_IMAGE=linux-arm64
ARG VERSION=1.1.0

# copy tar file from builder
COPY --from=cannelloni-builder /tmp/cannelloni.tar.gz /cannelloni_${DOCKCROSS_IMAGE}_${VERSION}.tar.gz

# copy directory from builder
# COPY --from=cannelloni-builder /cannelloni_${DOCKCROSS_IMAGE}_${VERSION}/ /cannelloni_${DOCKCROSS_IMAGE}_${VERSION}/
