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
    ttyd \
    && rm -rf /var/lib/apt/lists/*

# If ttyd wasn't installed or needs fallback, ensure it exists
RUN which ttyd || ( \
    ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then TTYD_ARCH="x86_64"; else TTYD_ARCH="aarch64"; fi && \
    curl -sSL "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.${TTYD_ARCH}" -o /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd \
)

# Copy rootfs scripts
COPY rootfs/ /

RUN chmod +x /run.sh /ui.sh /fetch-agy.sh

WORKDIR /config

CMD ["/run.sh"]
