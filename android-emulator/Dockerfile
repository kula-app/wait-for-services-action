# syntax=docker/dockerfile:1

FROM bitnami/minideb:bookworm

LABEL maintainer="kula app GmbH <opensource@kula.app>"
LABEL description="Minimal container for checking Android emulator boot status via ADB"

# Install android-tools-adb and netcat
RUN apt-get update -y && apt-get install -y --no-install-recommends \
  android-tools-adb \
  netcat-openbsd \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Smoke tests
RUN set -x && \
  adb --version && \
  nc -h

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
