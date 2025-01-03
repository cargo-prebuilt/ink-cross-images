# syntax=docker/dockerfile:1
ARG DEBIAN_VERSION=12-slim
FROM debian:$DEBIAN_VERSION

# Build Args
ARG EXT_CURL_CMD="curl --retry 3 -fsSL --tlsv1.2"
ARG TARGETARCH

# Versioning
ARG CMAKE_VERSION=3.31.2
ENV CMAKE_VERSION=${CMAKE_VERSION}

# Do not set
ENV DEBIAN_FRONTEND=noninteractive

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    CARGO_TERM_COLOR=always

# Copy required scripts and Dockerfile
COPY ./scripts/base/step0 /ink/scripts/base/step0
COPY ./docker/base/step0.Dockerfile /ink/dockerfiles/

# Upgrade and install apt packages
RUN /ink/scripts/base/step0/manage-apt.sh

# Install cmake
RUN /ink/scripts/base/step0/install-cmake.sh
COPY ./cmake/toolchain-gcc.cmake /opt/toolchain.cmake

# Cargo prebuilt
RUN /ink/scripts/base/step0/install-cargo-prebuilt.sh

WORKDIR /project
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "auditable", "build" ]
