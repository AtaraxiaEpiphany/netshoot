
FROM ubuntu:latest as fetcher

ARG GH_TOKEN

ENV GH_TOKEN=${GH_TOKEN:-}

# Install essential packages for downloading
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    wget \
    jq

# Copy and run binary fetching script - continue even if some downloads fail
COPY build/scripts/fetch_binaries.sh /tmp/fetch_binaries.sh
RUN chmod +x /tmp/fetch_binaries.sh && \
    /tmp/fetch_binaries.sh

FROM ubuntu:latest

# Enable Ubuntu Universe repository and updates
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get upgrade -y

# Install system dependencies
RUN set -ex && \
    apt-get install -y \
    # Networking Tools
    apache2-utils \
    bind9-utils \
    bridge-utils \
    conntrack \
    curl \
    dhcping \
    ethtool \
    iftop \
    iperf3 \
    iproute2 \
    ipset \
    iptables \
    iputils-ping \
    ipvsadm \
    mtr \
    net-tools \
    netcat-openbsd \
    nftables \
    ngrep \
    nmap \
    openssl \
    socat \
    speedtest-cli \
    tcpdump \
    tcptraceroute \
    traceroute \
    \
    # System Utilities
    bash \
    busybox \
    file \
    jq \
    libc6 \
    util-linux \
    zsh \
    ufw \
    rsync \
    expect \
    pv \
    unzip \
    procps \
    man-db \
    \
    # Development and Debugging
    git \
    httpie \
    #curlie \
    ltrace \
    openssh-client \
    perl \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    python3-setuptools \
    build-essential \
    cmake \
    ccache \
    gdb \
    g++ \
    gcc \
    clang \
    make \
    valgrind \
    bear \
    maven \
    openjdk-21-jdk \
    strace \
    swaks \
    vim \
    tmux \
    \
    # Monitoring and Performance
    fping \
    iftop \
    snmp \
    \
    # Scripting and Extended Utilities
    dnsutils \
    net-tools \
    scapy \
    tshark \
    \
    # Modern unix
    bat \
    #delta \
    #procs \
    fd-find \
    ripgrep \
    hyperfine \
    gping \
    #xh \
    \
    # Vncserver relate
    xdg-utils \
    libx11-dev \
    libxext-dev \
    gnome-panel \
    gnome-settings-daemon \
    metacity \
    nautilus \
    gnome-terminal \
    ubuntu-desktop \
    tightvncserver \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN yes | unminimize

# Installing additional tools from fetcher stage (ignore if missing)
COPY --from=fetcher /tmp/ctop /usr/local/bin/ctop 2>/dev/null || true
COPY --from=fetcher /tmp/calicoctl /usr/local/bin/calicoctl 2>/dev/null || true
COPY --from=fetcher /tmp/termshark /usr/local/bin/termshark 2>/dev/null || true
COPY --from=fetcher /tmp/grpcurl /usr/local/bin/grpcurl 2>/dev/null || true
COPY --from=fetcher /tmp/fortio /usr/local/bin/fortio 2>/dev/null || true

# Make sure copied binaries are executable
RUN chmod +x /usr/local/bin/*

# Set up user and environment
USER root
WORKDIR /root
ENV HOSTNAME=netshoot

# Install Oh My Zsh and plugins
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Copy dotfiles and configuration files
COPY build/dotfiles /root/dotfiles
COPY dotfiles/.config /root/.config

# Install and set up zsh, fzf, zim, and other configurations

# Fix permissions
RUN chmod -R g=u /root \
    && chown root:root /usr/bin/dumpcap

# Set default shell
CMD ["zsh"]
