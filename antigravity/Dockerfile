ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm
FROM ${BUILD_FROM}

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    SHELL=/bin/bash \
    TERM=xterm-256color \
    COLORTERM=truecolor \
    DEBIAN_FRONTEND=noninteractive

# Install purpose-built Home Assistant agent toolchain (lean & fast)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    wget \
    jq \
    git \
    gh \
    openssh-client \
    tar \
    gzip \
    xz-utils \
    unzip \
    procps \
    psmisc \
    sudo \
    tmux \
    ripgrep \
    fd-find \
    sqlite3 \
    mosquitto-clients \
    python3 \
    python3-venv \
    nano \
    less \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# Install multi-arch static binaries: ttyd, Home Assistant CLI (ha), Docker CLI, and uv
ARG DOCKER_VERSION=27.5.1
ARG TTYD_VERSION=1.7.7
RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "${ARCH}" in \
      x86_64|amd64) \
        TTYD_ARCH="x86_64"; \
        HA_ARCH="amd64"; \
        DOCKER_ARCH="x86_64"; \
        UV_ARCH="x86_64"; \
        ;; \
      aarch64|arm64) \
        TTYD_ARCH="aarch64"; \
        HA_ARCH="aarch64"; \
        DOCKER_ARCH="aarch64"; \
        UV_ARCH="aarch64"; \
        ;; \
      *) \
        echo "Unsupported architecture: ${ARCH}" >&2; \
        exit 1; \
        ;; \
    esac; \
    # 1. ttyd web terminal
    curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.${TTYD_ARCH}" -o /usr/local/bin/ttyd; \
    chmod +x /usr/local/bin/ttyd; \
    # 2. Official Home Assistant CLI (ha)
    curl -fsSL "https://github.com/home-assistant/cli/releases/latest/download/ha_${HA_ARCH}" -o /usr/bin/ha; \
    chmod +x /usr/bin/ha; \
    ln -sf /usr/bin/ha /usr/local/bin/ha; \
    # 3. Lightweight static Docker CLI (talks to host /var/run/docker.sock)
    curl -fsSL "https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_VERSION}.tgz" -o /tmp/docker.tgz; \
    tar -xzf /tmp/docker.tgz -C /tmp docker/docker; \
    mv /tmp/docker/docker /usr/local/bin/docker; \
    chmod +x /usr/local/bin/docker; \
    rm -rf /tmp/docker /tmp/docker.tgz; \
    # 4. Astral uv / uvx Python package & tool runner
    curl -fsSL "https://github.com/astral-sh/uv/releases/latest/download/uv-${UV_ARCH}-unknown-linux-gnu.tar.gz" -o /tmp/uv.tar.gz; \
    tar -xzf /tmp/uv.tar.gz -C /tmp; \
    mv "/tmp/uv-${UV_ARCH}-unknown-linux-gnu/uv" /usr/local/bin/uv; \
    mv "/tmp/uv-${UV_ARCH}-unknown-linux-gnu/uvx" /usr/local/bin/uvx; \
    chmod +x /usr/local/bin/uv /usr/local/bin/uvx; \
    rm -rf "/tmp/uv-${UV_ARCH}-unknown-linux-gnu" /tmp/uv.tar.gz

# Copy rootfs scripts
COPY rootfs/ /

RUN chmod +x /run.sh /ui.sh /fetch-agy.sh /agy-loop.sh

LABEL org.opencontainers.image.title="Home Assistant Add-on: Google Antigravity CLI" \
      org.opencontainers.image.description="Google Antigravity AI coding assistant and remote-control daemon with persistent Ingress TUI" \
      org.opencontainers.image.source="https://github.com/mostlyrobots/agy-ha" \
      org.opencontainers.image.licenses="MIT"

WORKDIR /config

ENTRYPOINT ["/run.sh"]
