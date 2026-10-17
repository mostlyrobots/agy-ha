ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm
FROM ${BUILD_FROM}

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    SHELL=/bin/bash \
    TERM=xterm-256color

# Install developer tools, Docker client, Node.js, Python, and ttyd
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    wget \
    jq \
    git \
    openssh-client \
    tar \
    gzip \
    procps \
    psmisc \
    sudo \
    tmux \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Install ttyd multi-arch release binary
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
      x86_64|amd64) TTYD_ARCH="x86_64" ;; \
      aarch64|arm64) TTYD_ARCH="aarch64" ;; \
      *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac && \
    curl -sSL "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.${TTYD_ARCH}" -o /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd

# Copy rootfs scripts
COPY rootfs/ /

RUN chmod +x /run.sh /ui.sh /fetch-agy.sh

WORKDIR /config

ENTRYPOINT ["/run.sh"]
