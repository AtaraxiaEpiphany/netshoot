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

# Copy dev utils installation script
COPY build/scripts/install_dev_utils.sh /tmp/install_dev_utils.sh

# Enable Ubuntu Universe repository and updates
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get upgrade -y

# Change linux mirros
RUN bash <(curl -sSL https://linuxmirrors.cn/main.sh)

# Install system dependencies and development utilities
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
    whois \
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
    tree \
    xz-utils \
    tar \
    bzip2 \
    expect \
    pv \
    unzip \
    zip \
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
    pipx \
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
    fd-find \
    ripgrep \
    hyperfine \
    gping \
    \
    # VNC server related
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
    && chmod +x /tmp/install_dev_utils.sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN yes | unminimize

# Installing additional tools from fetcher stage (ignore if missing)
COPY --from=fetcher /tmp/ctop /usr/local/bin/ctop
COPY --from=fetcher /tmp/calicoctl /usr/local/bin/calicoctl
COPY --from=fetcher /tmp/termshark /usr/local/bin/termshark
COPY --from=fetcher /tmp/grpcurl /usr/local/bin/grpcurl
COPY --from=fetcher /tmp/fortio /usr/local/bin/fortio
COPY --from=fetcher /tmp/witr /usr/local/bin/witr
COPY --from=fetcher /tmp/websocat /usr/local/bin/websocat

# Make sure copied binaries are executable
RUN chmod +x /usr/local/bin/*

# Set up user and environment
USER root
WORKDIR /root
ENV HOSTNAME=netshoot

# Install zim
RUN /bin/zsh -c "curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh"

# Copy dotfiles and configuration files
COPY build/dotfiles /tmp/dotfiles
RUN rsync -avvzhPi --remove-source-files /tmp/dotfiles/.config/ /root/

RUN /usr/bin/env zsh -c "/tmp/install_dev_utils.sh && rm /tmp/install_dev_utils.sh"

# Fix permissions
RUN chmod -R g=u /root \
    && chown root:root /usr/bin/dumpcap

# Set default shell
CMD ["zsh"]
