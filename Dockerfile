ARG ARCHITECTURE=linux-arm64

FROM dockcross/$ARCHITECTURE as cannelloni-builder
ARG VERSION=1.1.0
ARG HASH=0dcb9277b21f916f5646574b9b2229d3b8e97d5e99b935a4d0b7509a5f0ccdcd
ARG ARCHITECTURE=linux-arm64
ARG DEBIAN_ARCHITECTURE=arm64

RUN dpkg --add-architecture $DEBIAN_ARCHITECTURE
RUN apt update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates wget build-essential cmake \
    libsctp-dev:$DEBIAN_ARCHITECTURE lksctp-tools:$DEBIAN_ARCHITECTURE

RUN mkdir /tmp/cannelloni
WORKDIR /tmp/cannelloni
RUN wget https://github.com/mguentner/cannelloni/archive/refs/tags/v$VERSION.tar.gz -O cannelloni-$VERSION.tar.gz
RUN echo "$HASH cannelloni-$VERSION.tar.gz" | sha256sum --check --status
RUN tar --strip-components=1 -xvf cannelloni-$VERSION.tar.gz

# copy installed libraries to expected target location for cmake toolchain
COPY copylib.sh /copylib.sh
RUN /copylib.sh

RUN cmake -DCMAKE_BUILD_TYPE=Release && make

WORKDIR /tmp/

# copy libcannelloni to target directory
RUN cp --remove-destination /tmp/cannelloni/libcannelloni-common.so.0.0.1 /tmp/cannelloni/libcannelloni-common.so.0

# copy libsctp library to target directory
RUN cp --no-dereference --preserve=links /usr/lib/*/libsctp* /tmp/cannelloni
RUN curl https://raw.githubusercontent.com/sctp/lksctp-tools/master/COPYING.lib --output /tmp/cannelloni/libsctp-license.txt

# add note about source
RUN echo "You can find a copy of the cannelloni source code at: https://github.com/mguentner/cannelloni/archive/refs/tags/v$VERSION.tar.gz" > /tmp/cannelloni/SOURCES.md
RUN echo "You can find a copy of the libsctp source and license here: https://github.com/sctp/lksctp-tools" >> /tmp/cannelloni/SOURCES.md

# create tar file as output
RUN tar cf /tmp/cannelloni.tar.gz \
    cannelloni/cannelloni cannelloni/libcannelloni-common.so.0 cannelloni/gpl-2.0.txt cannelloni/README.md cannelloni/SOURCES.md \
    cannelloni/libsctp*

# create directory as output
# RUN mkdir -p /cannelloni_${ARCHITECTURE}_${VERSION}/
# RUN cp /tmp/cannelloni/libcannelloni-common.so.0 /tmp/cannelloni/cannelloni /tmp/cannelloni/README.md /tmp/cannelloni/gpl-2.0.txt /cannelloni_${ARCHITECTURE}_${VERSION}/

FROM scratch AS export-stage
ARG ARCHITECTURE=linux-arm64
ARG VERSION=1.1.0

# copy tar file from builder
COPY --from=cannelloni-builder /tmp/cannelloni.tar.gz /cannelloni_${ARCHITECTURE}_${VERSION}.tar.gz

# copy directory from builder
# COPY --from=cannelloni-builder /cannelloni_${ARCHITECTURE}_${VERSION}/ /cannelloni_${ARCHITECTURE}_${VERSION}/
