#!/usr/bin/env bash
#
# WSL2 Environment Setup Script for Air-Gapped Export
#
# This script sets up a WSL2 Ubuntu environment with all configurations and
# internet-required tools. After running, export the WSL instance as a tar
# for import into an air-gapped internal network.
#
# Prerequisites:
#   - Fresh WSL2 Ubuntu installation
#   - Internet access (for downloading tools from GitHub, npm, etc.)
#   - sudo privileges
#
# Usage:
#   git clone <this-repo> && cd netshoot
#   bash build/scripts/setup_wsl.sh            # Run / Resume
#   bash build/scripts/setup_wsl.sh --reset    # Clear checkpoint and restart
#
# After setup:
#   wsl --export <distro> netshoot.tar        # Export
#   wsl --import netshoot <path> netshoot.tar  # Import on air-gapped machine
#
# All apt packages are pre-installed during setup (Phase 1).
# Reference list: build/scripts/internal_apt_packages.txt
#

set -euo pipefail

# --reset: clear checkpoint and exit
if [[ "${1:-}" == "--reset" ]]; then
    rm -f "${CHECKPOINT_FILE:-$HOME/.wsl_setup_checkpoint}"
    echo "[SETUP] Checkpoint cleared."
    exit 0
fi

# ============================================================
# Configuration
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOTFILES_DIR="$PROJECT_DIR/build/dotfiles/.config"

# Mirror source for LinuxMirrors (change apt/docker registry mirrors)
# Common options: mirrors.aliyun.com, mirrors.ustc.edu.cn, mirrors.tuna.tsinghua.edu.cn
# Set to "" to skip mirror change
MIRROR_SOURCE="${MIRROR_SOURCE:-mirrors.aliyun.com}"

# Default WSL user
TARGET_USER="${WSL_USER:-tulip}"

# Support root execution (Docker test)
if [[ "$(id -u)" -eq 0 ]]; then
    # Running as root: sudo passthrough (handles VAR=value command syntax)
    sudo() {
        if [[ "$1" == *=* ]]; then env "$@"; else "$@"; fi
    }
    # Create default user if it doesn't exist
    if ! id "$TARGET_USER" &>/dev/null; then
        useradd -s /bin/zsh -m "$TARGET_USER"
        usermod -aG sudo "$TARGET_USER"
        # Allow passwordless sudo
        echo "$TARGET_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$TARGET_USER"
        chmod 440 "/etc/sudoers.d/$TARGET_USER"
    fi
fi
TARGET_HOME="$(eval echo "~$TARGET_USER")"

# Ensure all child processes (zim, nvm, uv, cargo, etc.) write to TARGET_USER's home
export HOME="$TARGET_HOME"

# Architecture detection
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
esac

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()    { echo -e "\n${GREEN}[SETUP]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()  { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ============================================================
# Checkpoint System
# ============================================================

CHECKPOINT_FILE="${CHECKPOINT_FILE:-$TARGET_HOME/.wsl_setup_checkpoint}"

phase() {
    local num=$1
    local desc="$2"
    if grep -q "^phase_${num}=done$" "$CHECKPOINT_FILE" 2>/dev/null; then
        log "Phase ${num}/19: ${desc} ${CYAN}[CACHED]${NC}"
        return 1
    fi
    log "Phase ${num}/19: ${desc}"
    return 0
}

phase_done() {
    echo "phase_${1}=done" >> "$CHECKPOINT_FILE"
}

# Show resume info
if [[ -f "$CHECKPOINT_FILE" ]]; then
    cached=$(grep -c '=done$' "$CHECKPOINT_FILE" 2>/dev/null || echo 0)
    if [[ "$cached" -gt 0 ]]; then
        log "Resuming from checkpoint ($cached/19 phases cached, file: $CHECKPOINT_FILE)"
    fi
fi

# ============================================================
# Phase 1: System Packages
# ============================================================

if phase 1 "Installing system packages..."; then

# Prerequisites for add-apt-repository and LinuxMirrors
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl wget jq software-properties-common

# Change apt sources to domestic mirror (https://github.com/SuperManito/LinuxMirrors)
if [[ -n "$MIRROR_SOURCE" ]]; then
    log "  Changing apt sources to $MIRROR_SOURCE..."
    bash <(curl -sSL https://linuxmirrors.cn/main.sh) \
        --source "$MIRROR_SOURCE" \
        --protocol https \
        --use-intranet-source false \
        --backup true \
        --upgrade-software false \
        --clean-cache false \
        --ignore-backup-tips \
        || warn "Mirror change failed, continuing with default sources"
fi

# Enable universe repository
sudo add-apt-repository universe
sudo apt-get update

# Install all packages (pre-installed for air-gapped export)
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    `# --- Networking Tools ---` \
    apache2-utils bind9-utils bridge-utils conntrack dhcping ethtool \
    iftop iperf3 iproute2 ipset iptables iputils-ping ipvsadm \
    mtr whois net-tools netcat-openbsd nftables ngrep nmap openssl \
    socat speedtest-cli tcpdump tcpflow tcptraceroute traceroute telnet \
    \
    `# --- System Utilities ---` \
    bash busybox file jq libc6 util-linux zsh ufw sudo rsync tree \
    xz-utils tar bzip2 expect pv unzip zip procps man-db parallel \
    bsdiff xdelta3 linux-tools-common linux-tools-generic skopeo ffmpeg \
    qemu-system qemu-system-x86 git locales unzip pipx \
    \
    `# --- Development and Debugging ---` \
    httpie ltrace openssh-client openssh-server perl python3 python3-pip \
    python3-dev python3-venv python3-setuptools build-essential cmake \
    ccache gdb g++ gcc clang make valgrind bear maven openjdk-21-jdk \
    strace swaks vim tmux \
    \
    `# --- Monitoring and Performance ---` \
    fping snmp \
    \
    `# --- Scripting and Extended Utilities ---` \
    dnsutils python3-scapy tshark mitmproxy \
    \
    `# --- Modern Unix ---` \
    bat fd-find ripgrep hyperfine

phase_done 1
fi

# ============================================================
# Phase 2: Locale Setup
# ============================================================

if phase 2 "Setting up locale..."; then

sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

phase_done 2
fi

# ============================================================
# Phase 3: Default Shell
# ============================================================

if phase 3 "Setting zsh as default shell..."; then

sudo chsh -s "$(which zsh)" "$TARGET_USER"

phase_done 3
fi

# ============================================================
# Phase 4: Workspace Directories
# ============================================================

if phase 4 "Creating workspace directories..."; then

mkdir -p "$TARGET_HOME/Workspaces/Git"
mkdir -p "$TARGET_HOME/Workspaces/Projects"
mkdir -p "$TARGET_HOME/Workspaces/Utils"

phase_done 4
fi

# ============================================================
# Phase 5: External Binaries (GitHub Releases)
# ============================================================

if phase 5 "Fetching external binaries from GitHub releases..."; then

BIN_DIR="/tmp/wsl_binaries"
rm -rf "$BIN_DIR" && mkdir -p "$BIN_DIR"

get_latest_release() {
    local repo=$1
    local api="https://api.github.com/repos/$repo/releases/latest"
    local response
    if [[ -n "${GH_TOKEN:-}" ]]; then
        response=$(curl --silent -H "Authorization: token $GH_TOKEN" "$api") || { echo ""; return 1; }
    else
        response=$(curl --silent "$api") || { echo ""; return 1; }
    fi
    echo "$response" | jq -r '.tag_name'
}

# ctop
if VER=$(get_latest_release bcicen/ctop | sed 's/^v//') && [[ -n "$VER" ]]; then
    wget -q "https://github.com/bcicen/ctop/releases/download/v${VER}/ctop-${VER}-linux-${ARCH}" \
        -O "$BIN_DIR/ctop" && chmod +x "$BIN_DIR/ctop" && echo "  ctop $VER"
else warn "Failed to fetch ctop"; fi

# calicoctl
if VER=$(get_latest_release projectcalico/calico) && [[ -n "$VER" ]]; then
    wget -q "https://github.com/projectcalico/calico/releases/download/${VER}/calicoctl-linux-${ARCH}" \
        -O "$BIN_DIR/calicoctl" && chmod +x "$BIN_DIR/calicoctl" && echo "  calicoctl $VER"
else warn "Failed to fetch calicoctl"; fi

# grpcurl
case "$ARCH" in
    amd64) GRPC_ARCH=x86_64 ;;
    arm64) GRPC_ARCH="$ARCH" ;;
esac
if VER=$(get_latest_release fullstorydev/grpcurl | sed 's/^v//') && [[ -n "$VER" ]]; then
    wget -q "https://github.com/fullstorydev/grpcurl/releases/download/v${VER}/grpcurl_${VER}_linux_${GRPC_ARCH}.tar.gz" \
        -O "$BIN_DIR/grpcurl.tar.gz"
    tar -xzf "$BIN_DIR/grpcurl.tar.gz" -C "$BIN_DIR" grpcurl && chmod +x "$BIN_DIR/grpcurl"
    rm -f "$BIN_DIR/grpcurl.tar.gz" && echo "  grpcurl $VER"
else warn "Failed to fetch grpcurl"; fi

# fortio
if VER=$(get_latest_release fortio/fortio | sed 's/^v//') && [[ -n "$VER" ]]; then
    wget -q "https://github.com/fortio/fortio/releases/download/v${VER}/fortio-linux_${ARCH}-${VER}.tgz" \
        -O "$BIN_DIR/fortio.tgz" && \
    tar -xzf "$BIN_DIR/fortio.tgz" -C "$BIN_DIR" --strip-components=2 usr/bin/fortio && \
    chmod +x "$BIN_DIR/fortio" && rm -f "$BIN_DIR/fortio.tgz" && echo "  fortio $VER"
else warn "Failed to fetch fortio"; fi

# websocat
if VER=$(get_latest_release vi/websocat) && [[ -n "$VER" ]]; then
    wget -q "https://github.com/vi/websocat/releases/download/${VER}/websocat.x86_64-unknown-linux-musl" \
        -O "$BIN_DIR/websocat" && chmod +x "$BIN_DIR/websocat" && echo "  websocat $VER"
else warn "Failed to fetch websocat"; fi

# termshark
if VER=$(get_latest_release gcla/termshark | sed 's/^v//') && [[ -n "$VER" ]]; then
    case "$ARCH" in
        amd64) TERM_ARCH=x64 ;;
        arm64) TERM_ARCH="$ARCH" ;;
    esac
    wget -q "https://github.com/gcla/termshark/releases/download/v${VER}/termshark_${VER}_linux_${TERM_ARCH}.tar.gz" \
        -O "$BIN_DIR/termshark.tar.gz"
    tar -xzf "$BIN_DIR/termshark.tar.gz" -C "$BIN_DIR" \
        --strip-components=1 "termshark_${VER}_linux_${TERM_ARCH}/termshark"
    chmod +x "$BIN_DIR/termshark" && rm -f "$BIN_DIR/termshark.tar.gz" && echo "  termshark $VER"
else warn "Failed to fetch termshark"; fi

# witr
if VER=$(get_latest_release pranshuparmar/witr) && [[ -n "$VER" ]]; then
    wget -q "https://github.com/pranshuparmar/witr/releases/download/${VER}/witr-linux-${ARCH}" \
        -O "$BIN_DIR/witr" && chmod +x "$BIN_DIR/witr" && echo "  witr $VER"
else warn "Failed to fetch witr"; fi

# Install binaries to system path
log "  Installing binaries to /usr/local/bin..."
sudo cp "$BIN_DIR"/* /usr/local/bin/ 2>/dev/null || true
rm -rf "$BIN_DIR"

phase_done 5
fi

# ============================================================
# Phase 6: Zim Framework
# ============================================================

if phase 6 "Installing Zim framework..."; then

zsh -c 'curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh' || warn "Zim install had issues"

phase_done 6
fi

# ============================================================
# Phase 7: Dotfiles and Configurations
# ============================================================

if phase 7 "Copying dotfiles..."; then

rsync -avzh "$DOTFILES_DIR/" "$TARGET_HOME/"

# Append zshrc_extra to .zshrc (Zim already created its own .zshrc)
cat "$TARGET_HOME/.zshrc_extra" >> "$TARGET_HOME/.zshrc"

# Fix hardcoded paths in VNC startup scripts
sed -i 's|/home/docker/|$HOME/|g' "$TARGET_HOME/.xstartup" 2>/dev/null || true

# Add $HOME/go/bin to PATH for go-installed tools (curlie, glow, etc.)
grep -q '\$HOME/go/bin' "$TARGET_HOME/.shellrc" 2>/dev/null || \
    sed -i '/^export PATH.*\/usr\/local\/go\/bin/a export PATH="$PATH:$HOME/go/bin"' "$TARGET_HOME/.shellrc"

phase_done 7
fi

# ============================================================
# Phase 8: Zim Modules + p10k gitstatus
# ============================================================

if phase 8 "Installing Zim modules..."; then

zsh -c 'source ~/.zshrc 2>/dev/null; zimfw install' || warn "Zim module install had issues"

ZIM_HOME="${ZIM_HOME:-$TARGET_HOME/.zim}"
if [[ -f "$ZIM_HOME/modules/powerlevel10k/gitstatus/install" ]]; then
    "$ZIM_HOME/modules/powerlevel10k/gitstatus/install" -f || warn "gitstatus install failed"
fi

phase_done 8
fi

# ============================================================
# Phase 9: nvm + Node.js
# ============================================================

if phase 9 "Installing nvm and Node.js LTS..."; then

export NVM_DIR="$TARGET_HOME/.nvm"
if [[ ! -d "$NVM_DIR" ]]; then
    git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    (cd "$NVM_DIR" && git checkout "$(git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1))")
fi
# nvm uses unset variables internally; temporarily disable nounset
# shellcheck source=/dev/null
set +u
. "$NVM_DIR/nvm.sh"
nvm install --lts && nvm use --lts
set -u

phase_done 9
fi

# ============================================================
# Phase 10: Cargo (Rust Toolchain) — before Neovim for tree-sitter-cli
# ============================================================

if phase 10 "Installing Rust toolchain (cargo)..."; then

export RUSTUP_HOME="$TARGET_HOME/.rustup"
export CARGO_HOME="$TARGET_HOME/.cargo"

# Earlier phases ran as root and wrote to $TARGET_HOME — fix ownership before dropping privileges
chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME"

if [[ "$(id -u)" -eq 0 ]]; then
    # Drop privileges — rustup refuses to run when $HOME ≠ euid home
    runuser -u "$TARGET_USER" -- \
        env HOME="$TARGET_HOME" RUSTUP_HOME="$RUSTUP_HOME" CARGO_HOME="$CARGO_HOME" \
        bash -c '
            set -euo pipefail
            curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
            export PATH="$HOME/.cargo/bin:$PATH"
            cargo install gping
            cargo install git-delta
            cargo install procs
            cargo install tree-sitter-cli
            cargo install mcat
        '
else
    sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" RUSTUP_HOME="$RUSTUP_HOME" CARGO_HOME="$CARGO_HOME" \
        bash -c '
            set -euo pipefail
            curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
            export PATH="$HOME/.cargo/bin:$PATH"
            cargo install gping
            cargo install git-delta
            cargo install procs
            cargo install tree-sitter-cli
            cargo install mcat
        '
    export PATH="$CARGO_HOME/bin:$PATH"
fi

phase_done 10
fi

# ============================================================
# Phase 11: Neovim + LazyVim
# ============================================================

if phase 11 "Installing Neovim..."; then

NVIM_ARCH="x86_64"
case "$(uname -m)" in
    aarch64) NVIM_ARCH="arm64" ;;
esac

curl -LO "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"
sudo rm -rf "/opt/nvim-linux-${NVIM_ARCH}"
sudo tar -C /opt -xzf "nvim-linux-${NVIM_ARCH}.tar.gz"
rm -f "nvim-linux-${NVIM_ARCH}.tar.gz"

# Update .shellrc with correct nvim path
sed -i "s|/opt/nvim-linux-x86_64/bin|/opt/nvim-linux-${NVIM_ARCH}/bin|" "$TARGET_HOME/.shellrc"

log "  Configuring LazyVim..."
export PATH="$PATH:/opt/nvim-linux-${NVIM_ARCH}/bin:$CARGO_HOME/bin"

if [[ ! -d "$TARGET_HOME/.config/nvim" ]]; then
    git clone --depth=1 https://github.com/LazyVim/starter "$TARGET_HOME/.config/nvim"
fi

# Copy custom nvim config (from dotfiles rsync'd to $HOME)
mkdir -p "$TARGET_HOME/.config/nvim/lua/config"
cp -f "$TARGET_HOME/init.lua" "$TARGET_HOME/.config/nvim/init.lua"
cp -f "$TARGET_HOME/config.lua" "$TARGET_HOME/.config/nvim/lua/config/config.lua"

# Sync LazyVim plugins (tree-sitter-cli from cargo is now available)
nvim --headless "+Lazy! sync" +qa || warn "LazyVim sync had issues"

phase_done 11
fi

# ============================================================
# Phase 12: fzf
# ============================================================

if phase 12 "Installing fzf..."; then

if [[ ! -d "$TARGET_HOME/.fzf" ]]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$TARGET_HOME/.fzf"
fi
"$TARGET_HOME/.fzf/install" --bin

phase_done 12
fi

# ============================================================
# Phase 13: Podman
# ============================================================

if phase 13 "Installing Podman..."; then

sudo apt-get install -y podman fuse-overlayfs || warn "Podman apt install failed"
podman machine init 2>&1 || warn "podman machine init failed (may need virtualization support)"

phase_done 13
fi

# ============================================================
# Phase 14: uv (Python Package Manager)
# ============================================================

if phase 14 "Installing uv..."; then

chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME"

if [[ "$(id -u)" -eq 0 ]]; then
    runuser -u "$TARGET_USER" -- env HOME="$TARGET_HOME" \
        bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
else
    sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" \
        bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
fi || warn "uv install failed"

phase_done 14
fi

# ============================================================
# Phase 15: Go
# ============================================================

if phase 15 "Installing Go..."; then

GO_VERSION=1.26.3

case "$(uname -m)" in
    x86_64) GO_ARCH="amd64" ;;
    aarch64) GO_ARCH="arm64" ;;
esac
sudo rm -rf /usr/local/go
wget -q -O- "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" | sudo tar -C /usr/local -xzf -

phase_done 15
fi

# ============================================================
# Phase 16: Claude Code Ecosystem
# ============================================================

if phase 16 "Installing Claude Code and ecosystem..."; then

CLAUDE_BIN="$TARGET_HOME/.local/bin/claude"

run_as_target() {
    if [[ "$(id -u)" -eq 0 ]]; then
        runuser -u "$TARGET_USER" -- env HOME="$TARGET_HOME" PATH="$TARGET_HOME/.local/bin:$PATH" "$@"
    else
        sudo -u "$TARGET_USER" env HOME="$TARGET_HOME" PATH="$TARGET_HOME/.local/bin:$PATH" "$@"
    fi
}

# Fix ownership before running as target user
chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME"

# Claude Code CLI — must run as target user so install.sh writes to correct $HOME
run_as_target bash -c '
    set -euo pipefail
    curl -fsSL https://claude.ai/install.sh | bash
' || warn "Claude Code install failed"

# Plugins
if [[ -x "$CLAUDE_BIN" ]]; then
    for plugin in \
        "anthropics/skills" \
        "anthropics/claude-plugins-official" \
        "obra/superpowers-marketplace" \
        "OthmanAdi/planning-with-pages" \
        "K-Dense-AI/claude-scientific-skills" \
        "jarrodwatts/claude-hud" \
        "kepano/obsidian-skills" \
        "affaan-m/everything-claude-code"; do
        run_as_target "$CLAUDE_BIN" plugin marketplace add "$plugin" 2>/dev/null \
            || warn "Plugin add failed: $plugin"
    done
else
    warn "claude binary not found at $CLAUDE_BIN, skipping plugins"
fi

# SuperClaude
run_as_target pipx install superclaude 2>/dev/null && run_as_target superclaude install \
    || warn "superclaude install failed"

phase_done 16
fi

# ============================================================
# Phase 17: Modern Unix Tools
# ============================================================

if phase 17 "Installing modern Unix tools..."; then

chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME"

# Go-based tools
export PATH="/usr/local/go/bin:$TARGET_HOME/go/bin:$PATH"
go install github.com/rs/curlie@latest
go install github.com/charmbracelet/glow/v2@latest

phase_done 17
fi

# ============================================================
# Phase 18: Google Chrome
# ============================================================

if phase 18 "Installing Google Chrome..."; then

if [[ "$(uname -m)" == "x86_64" ]]; then
    deb=$(mktemp)
    wget -O "$deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i "$deb" || sudo apt-get install -f -y
    rm -f "$deb"
else
    warn "Chrome not available for $(uname -m), skipping"
fi

phase_done 18
fi

# ============================================================
# Phase 19: WSL Configuration + Internal Package List
# ============================================================

if phase 19 "Finalizing WSL configuration..."; then

# /etc/wsl.conf - sets default user after import
sudo tee /etc/wsl.conf > /dev/null <<EOF
[user]
default=$TARGET_USER

[network]
hostname=netshoot

[interop]
appendWindowsPath=false

[environment]
TERM=xterm
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8
EOF

# /etc/environment
sudo tee /etc/environment > /dev/null <<'EOF'
HOSTNAME=netshoot
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8
EOF

# Generate internal network apt package list
cat > "$SCRIPT_DIR/internal_apt_packages.txt" << 'PKGLIST'
# Pre-installed Apt Packages (Reference List)
# These packages are installed during setup_wsl.sh Phase 1.
# This list is for reference only -- no post-import installation needed.
#
# If packages need to be reinstalled on the internal network:
#   sudo apt update && sudo apt install -y $(grep -v '^#' internal_apt_packages.txt | tr '\n' ' ')

# Networking Tools
apache2-utils
bind9-utils
bridge-utils
conntrack
dhcping
ethtool
iftop
iperf3
iproute2
ipset
iptables
iputils-ping
ipvsadm
mtr
whois
net-tools
netcat-openbsd
nftables
ngrep
nmap
openssl
socat
tcpdump
tcpflow
tcptraceroute
traceroute
telnet
# speedtest-cli - may not be in mirror

# System Utilities
bash
busybox
file
jq
libc6
util-linux
zsh
ufw
sudo
rsync
tree
xz-utils
tar
bzip2
expect
pv
unzip
zip
procps
man-db
parallel
bsdiff
xdelta3
skopeo
ffmpeg
qemu-system
qemu-system-x86

# Development and Debugging
git
httpie
ltrace
openssh-client
openssh-server
perl
python3
python3-pip
pipx
python3-dev
python3-venv
python3-setuptools
build-essential
cmake
ccache
gdb
g++
gcc
clang
make
valgrind
bear
maven
openjdk-21-jdk
strace
swaks
vim
tmux

# Monitoring and Performance
fping
snmp

# Scripting and Extended Utilities
dnsutils
python3-scapy
tshark
mitmproxy

# Modern Unix (apt-available)
bat
fd-find
ripgrep
hyperfine

# VNC Server (optional - WSL2 with WSLg may not need these)
# Uncomment if VNC is needed:
# tracker
# dbus
# dbus-x11
# gnome-session
# xdg-utils
# libx11-dev
# libxext-dev
# gnome-panel
# gnome-settings-daemon
# metacity
# nautilus
# gnome-terminal
# ubuntu-desktop
# tightvncserver
PKGLIST

# Generate internal npm package install script
cat > "$SCRIPT_DIR/internal_npm_install.sh" << 'NPMLIST'
#!/usr/bin/env bash
#
# Internal Network npm Global Packages
# Run after importing WSL and installing Node.js (nvm use --lts)
#
# Usage: bash internal_npm_install.sh
#

set -euo pipefail

# Ensure nvm is loaded
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

echo "[NPM] Installing global packages via mirror..."

npm install -g @fission-ai/openspec@latest
npm install -g @anthropic-ai/claude-code
npm install -g @musistudio/claude-code-router
npm install -g @mariozechner/claude-trace
npm install -g gtop
npm install -g @mermaid-js/mermaid-cli

echo "[NPM] Done."
NPMLIST

# Fix home directory ownership
sudo chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME"

phase_done 19
fi

# ============================================================
# Cleanup & Summary
# ============================================================

rm -f "$CHECKPOINT_FILE"

echo ""
echo "========================================="
echo "  WSL2 Setup Complete!"
echo "========================================="
echo ""
echo "Export (on this machine):"
echo "  wsl --export <distro> netshoot.tar"
echo ""
echo "Import (on air-gapped machine):"
echo "  wsl --import netshoot <install-path> netshoot.tar"
echo ""
echo "Post-import (apt packages are pre-installed, reference list):"
echo "  $(basename "$SCRIPT_DIR")/internal_apt_packages.txt"
echo ""
echo "Post-import (install npm packages via mirror):"
echo "  bash $(basename "$SCRIPT_DIR")/internal_npm_install.sh"
echo ""
echo "Internal packages:"
echo "  apt: $SCRIPT_DIR/internal_apt_packages.txt"
echo "  npm: $SCRIPT_DIR/internal_npm_install.sh"
