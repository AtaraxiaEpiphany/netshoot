FROM ubuntu:latest as fetcher

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
RUN apt-get install -y --no-install-recommends \
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
    \
    # Development and Debugging
    git \
    httpie \
    ltrace \
    openssh-client \
    perl \
    python3-pip \
    python3-setuptools \
    strace \
    swaks \
    vim \
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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

# Copy configuration files

# Fix permissions
RUN chmod -R g=u /root \
    && chown root:root /usr/bin/dumpcap

# Set default shell
CMD ["zsh"]
