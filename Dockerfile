# syntax=docker/dockerfile:1

# ======================================================================================================================

#region -- Download Base --
FROM alpine AS dl
ARG TARGETARCH
WORKDIR /tmp

RUN apk add --no-cache curl unzip
#endregion

# ======================================================================================================================

#region -- Download: mongosh --
FROM dl AS dl-mongosh
ARG VERSION=2.5.0
RUN <<EOT ash
if [ "${TARGETARCH}" = "amd64" ]; then
  curl -L --fail "https://downloads.mongodb.com/compass/mongosh-${VERSION}-linux-x64.tgz" -o mongosh.tgz
elif [ "${TARGETARCH}" = "arm64" ]; then
  curl -L --fail "https://downloads.mongodb.com/compass/mongosh-${VERSION}-linux-arm64.tgz" -o mongosh.tgz
else
  echo "Unsupported target architecture: ${TARGETARCH}"
  exit 1
fi
EOT
#endregion

# ======================================================================================================================

#region -- Product --
FROM bitnami/minideb:bookworm AS main

# Metadata
LABEL maintainer="kula app GmbH <opensource@kula.app>"
LABEL description="Container with CLI utilities for checking service availability based on Alpine"

# Install common packages
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    curl \
    # Cleanup
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Install kafka-cat
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    kafkacat \
    # Cleanup
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Install android-tools
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    android-tools-adb \
    # Cleanup
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Install redis-cli
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    redis \
    # Cleanup
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Install netcat
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    netcat-openbsd \
    # Cleanup
    && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Install mongosh
COPY --from=dl-mongosh /tmp/mongosh.tgz /tmp/mongosh.tgz
RUN mkdir -p /tmp/mongosh && \
  tar -xvzf /tmp/mongosh.tgz --strip-components=1 -C /tmp/mongosh && \
  mkdir -p /usr/local/lib && \
  install \
    -o root \
    -g root \
    -m 0755 \
    /tmp/mongosh/bin/mongosh /usr/local/bin/mongosh && \
  cp -f /tmp/mongosh/bin/mongosh_crypt_v1.so /usr/local/lib/ && \
  rm -rf /tmp/mongosh.tgz /tmp/mongosh

# -----------
# Smoke Tests
# -----------

RUN set -x && \
    curl --version && \
    mongosh --version && \
    nc -h && \
    kcat -h && \
    redis-cli --version && \
    adb --version

# Prepare entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
#endregion

# ======================================================================================================================
