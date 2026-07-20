# syntax=docker/dockerfile:1
# Omada Controller v5.x installs MongoDB from Ubuntu's own archive
# (install.sh's non-v6 branch: `apt-get install mongodb-server-core`), which
# has been pulled from every currently-supported Ubuntu release (noble,
# jammy, focal) and from MongoDB's own official apt repo for every version
# below 6.0. mbentley/ubuntu:20.04 is the base this add-on used for all
# targets before the shared Dockerfile moved to ubuntu:24.04 for v6 support,
# and still carries a working mongodb-server-core package.
#
# Unlike ghcr.io/home-assistant/*-base-ubuntu, this is a bare Ubuntu image:
# s6-overlay and bashio aren't present, so both are installed here
# following the same recipe as home-assistant/docker-base's ubuntu variant
# (https://github.com/home-assistant/docker-base/blob/master/ubuntu/Dockerfile),
# so the shared entrypoint.sh/rootfs (written against bashio + s6 services.d)
# work unmodified.
FROM mbentley/ubuntu:20.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LANG="C.UTF-8" \
    DEBIAN_FRONTEND="noninteractive"

ARG BASHIO_REPOSITORY=hassio-addons/bashio
ARG BASHIO_VERSION=0.17.5
ARG S6_OVERLAY_REPOSITORY=just-containers/s6-overlay
# Pinned to match the exact version shipped in ghcr.io/home-assistant/amd64-base-ubuntu:24.04
# (verified by pulling and inspecting that image's layers directly), not docker-base's master
# branch, which has since moved past this.
ARG S6_OVERLAY_VERSION=3.2.2.0

ARG TARGETARCH
RUN if [ -z "${TARGETARCH}" ]; then \
      echo "TARGETARCH is not set, please use Docker BuildKit for the build." && exit 1; \
    fi

# Base packages needed to fetch/run s6-overlay and bashio (install.sh installs
# its own Omada-specific dependencies separately, below).
RUN apt-get update && apt-get install --no-install-recommends -y \
      bash \
      jq \
      curl \
      ca-certificates \
      xz-utils \
    && rm -rf /var/lib/apt/lists/*

# S6-Overlay
ADD --unpack=true "https://github.com/${S6_OVERLAY_REPOSITORY}/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" /
ADD --unpack=true "https://github.com/${S6_OVERLAY_REPOSITORY}/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz" /
ADD --unpack=true "https://github.com/${S6_OVERLAY_REPOSITORY}/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz" /
RUN case "${TARGETARCH}" in \
      amd64) S6_OVERLAY_ARCH="x86_64" ;; \
      arm64) S6_OVERLAY_ARCH="aarch64" ;; \
      *) echo "ERROR: Unsupported TARGETARCH: ${TARGETARCH}"; exit 1 ;; \
    esac \
    && curl -L -f -s "https://github.com/${S6_OVERLAY_REPOSITORY}/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz" \
      | tar Jxf - -C /

# bashio
ADD --unpack=true "https://github.com/${BASHIO_REPOSITORY}/archive/v${BASHIO_VERSION}.tar.gz" /usr/src/bashio
RUN mv /usr/src/bashio/bashio-*/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /usr/src/bashio

RUN mkdir -p /etc/fix-attrs.d /etc/services.d

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_SERVICES_READYTIME=50

COPY install.sh /
COPY healthcheck.sh /

# Home Assistant adds BUILD_ARCH, and buildx adds TARGETARCH; save the right one as ARCH
ARG BUILD_ARCH
ARG ARCH=${TARGETARCH:-${BUILD_ARCH:-}}

# HA supervisor passes the add-on version as BUILD_VERSION; CI passes INSTALL_VER directly.
ARG BUILD_VERSION
ARG INSTALL_VER=${BUILD_VERSION}

# install omada controller (instructions taken from install.sh)
RUN /install.sh && rm /install.sh

# copy entrypoint after the installation, to avoid rebuilding whole image
COPY entrypoint.sh /

# Set s6-overlay timeouts
# S6_SERVICES_GRACETIME: time (ms) to wait for services to stop (default 3000)
ENV S6_SERVICES_GRACETIME=55000

# Copy rootfs
COPY rootfs /

WORKDIR /opt/tplink/EAPController/lib
EXPOSE 8088 8043 8843 29810/udp 29811 29812 29813 29814
HEALTHCHECK --start-period=6m CMD /healthcheck.sh
VOLUME ["/data"]
ENTRYPOINT ["/init"]
