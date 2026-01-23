FROM ubuntu:latest as fetcher

ARG GH_TOKEN
ENV GH_TOKEN=${GH_TOKEN:-}

# Combine package installation and binary fetching in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    jq 

# Copy and run binary fetching script
COPY build/scripts/fetch_binaries.sh /tmp/fetch_binaries.sh
RUN chmod +x /tmp/fetch_binaries.sh \
    && /tmp/fetch_binaries.sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

FROM ubuntu:latest


# Enable Ubuntu Universe repository and prepare system
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      software-properties-common \
      curl \
      ca-certificates \
	&& add-apt-repository universe \
	&& apt-get update \
	&& apt-get upgrade -y \
    # Change linux mirrors with a modified script to reduce layers \
	&& /bin/bash -c "bash <(curl -sSL https://linuxmirrors.cn/main.sh)" \
    # Install all system dependencies in a single layer \
    && apt-get install -y \
      # Networking Tools \
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
	  tcpflow \
	  tcptraceroute \
	  traceroute \
	  telnet \
	  \
	  # System Utilities \
	  bash \
	  busybox \
	  file \
	  jq \
	  libc6 \
	  util-linux \
	  zsh \
	  ufw \
	  sudo \
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
	  parallel \
	  bsdiff \
	  xdelta3 \
	  linux-tools-common \
	  linux-tools-generic \
	  linux-tools-$(uname -r) \
	  # Development and Debugging \
	  git \
	  httpie \
	  #curlie \
	  ltrace \
	  openssh-client \
	  openssh-server \
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
	  # Monitoring and Performance \
	  fping \
	  iftop \
	  snmp \
	  \
	  # Scripting and Extended Utilities \
	  dnsutils \
	  net-tools \
	  scapy \
	  tshark \
	  mitmproxy \
	  \
	  # Modern unix \
	  bat \
	  fd-find \
	  ripgrep \
	  hyperfine \
	  gping \
	  \
	  # VNC server related \
	  tracker \
	  dbus \
	  dbus-x11 \
	  gnome-session \
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
    # Generate locales \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    # Unminimize for full documentation \
    && yes | unminimize \
    # Clean up to reduce image size \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Installing additional tools from fetcher stage in a single layer
COPY --from=fetcher /tmp/ctop /tmp/calicoctl /tmp/termshark /tmp/grpcurl /tmp/fortio /tmp/witr /tmp/websocat /usr/local/bin/

RUN chmod +x /usr/local/bin/* 

# Set up user and environment in a single layer
COPY build/dotfiles /tmp/dotfiles 
COPY build/scripts/install_dev_utils.sh /tmp/install_dev_utils.sh 
# Fix permissions
RUN chmod -R g=u /root \
    && chown root:root /usr/bin/dumpcap

# Set environment variables
ENV HOSTNAME=netshoot \
    TERM=xterm \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN  /usr/bin/env zsh -l -c "/tmp/install_dev_utils.sh" 


# Set default shell
USER root
WORKDIR /root/Workspaces
CMD ["zsh"]
