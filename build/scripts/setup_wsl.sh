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
#   bash build/scripts/setup_wsl.sh
#
# After setup:
#   wsl --export <distro> netshoot.tar        # Export
#   wsl --import netshoot <path> netshoot.tar  # Import on air-gapped machine
#
# Internal network (post-import) apt packages:
#   See generated file: build/scripts/internal_apt_packages.txt
#

set -euo pipefail

# ============================================================
# Configuration
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOTFILES_DIR="$PROJECT_DIR/build/dotfiles/.config"

# Support root execution (Docker test) via WSL_USER env var
if [[ "$(id -u)" -eq 0 ]]; then
    # Running as root: sudo passthrough (handles VAR=value command syntax)
    sudo() {
        if [[ "$1" == *=* ]]; then env "$@"; else "$@"; fi
    }
    TARGET_USER="${WSL_USER:?When running as root, set WSL_USER=<username>}"
else
    TARGET_USER="$(whoami)"
fi
TARGET_HOME="$(eval echo "~$TARGET_USER")"

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
NC='\033[0m'

log()    { echo -e "\n${GREEN}[SETUP]${NC} $1"; }
warn()   { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()  { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# ============================================================
# Phase 1: Minimal System Prerequisites
# ============================================================

log "Phase 1/18: Installing minimal prerequisites..."

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl wget jq git zsh rsync sudo \
    software-properties-common locales unzip pipx

# ============================================================
# Phase 2: Locale Setup
# ============================================================

log "Phase 2/18: Setting up locale..."

sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# ============================================================
# Phase 3: Default Shell
# ============================================================

log "Phase 3/18: Setting zsh as default shell..."

sudo chsh -s "$(which zsh)" "$TARGET_USER"

# ============================================================
# Phase 4: Workspace Directories
# ============================================================

log "Phase 4/18: Creating workspace directories..."

mkdir -p "$TARGET_HOME/Workspaces/git"
mkdir -p "$TARGET_HOME/Workspaces/Projects"
mkdir -p "$TARGET_HOME/Workspaces/Utils"

# ============================================================
# Phase 5: External Binaries (GitHub Releases)
# ============================================================

log "Phase 5/18: Fetching external binaries from GitHub releases..."

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

# ============================================================
# Phase 6: Zim Framework
# ============================================================

log "Phase 6/18: Installing Zim framework..."

zsh -c 'curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh' || warn "Zim install had issues"

# ============================================================
# Phase 7: Dotfiles and Configurations
# ============================================================

log "Phase 7/18: Copying dotfiles..."

rsync -avzh "$DOTFILES_DIR/" "$TARGET_HOME/"

# Append zshrc_extra to .zshrc (Zim already created its own .zshrc)
cat "$TARGET_HOME/.zshrc_extra" >> "$TARGET_HOME/.zshrc"

# Fix hardcoded paths in VNC startup scripts
sed -i 's|/home/docker/|$HOME/|g' "$TARGET_HOME/.xstartup" 2>/dev/null || true

# Add $HOME/go/bin to PATH for go-installed tools (curlie, glow, etc.)
grep -q '\$HOME/go/bin' "$TARGET_HOME/.shellrc" 2>/dev/null || \
    sed -i '/^export PATH.*\/usr\/local\/go\/bin/a export PATH="$PATH:$HOME/go/bin"' "$TARGET_HOME/.shellrc"

# ============================================================
# Phase 8: Zim Modules + p10k gitstatus
# ============================================================

log "Phase 8/18: Installing Zim modules..."

zsh -c 'source ~/.zshrc 2>/dev/null; zimfw install' || warn "Zim module install had issues"

ZIM_HOME="${ZIM_HOME:-$TARGET_HOME/.zim}"
if [[ -f "$ZIM_HOME/modules/powerlevel10k/gitstatus/install" ]]; then
    "$ZIM_HOME/modules/powerlevel10k/gitstatus/install" -f || warn "gitstatus install failed"
fi

# ============================================================
# Phase 9: nvm + Node.js
# ============================================================

log "Phase 9/18: Installing nvm and Node.js LTS..."

export NVM_DIR="$TARGET_HOME/.nvm"
if [[ ! -d "$NVM_DIR" ]]; then
    git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    (cd "$NVM_DIR" && git checkout "$(git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1))")
fi
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
nvm install --lts && nvm use --lts

# ============================================================
# Phase 10: Neovim + LazyVim
# ============================================================

NVIM_ARCH="x86_64"
case "$(uname -m)" in
    aarch64) NVIM_ARCH="arm64" ;;
esac

log "Phase 10/18: Installing Neovim..."

curl -LO "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"
sudo rm -rf "/opt/nvim-linux-${NVIM_ARCH}"
sudo tar -C /opt -xzf "nvim-linux-${NVIM_ARCH}.tar.gz"
rm -f "nvim-linux-${NVIM_ARCH}.tar.gz"

# Update .shellrc with correct nvim path
sed -i "s|/opt/nvim-linux-x86_64/bin|/opt/nvim-linux-${NVIM_ARCH}/bin|" "$TARGET_HOME/.shellrc"

log "  Configuring LazyVim..."
export PATH="$PATH:/opt/nvim-linux-${NVIM_ARCH}/bin"

if [[ ! -d "$TARGET_HOME/.config/nvim" ]]; then
    git clone --depth=1 https://github.com/LazyVim/starter "$TARGET_HOME/.config/nvim"
fi

# tree-sitter-cli -> install via npm mirror in internal network

# Copy custom nvim config (from dotfiles rsync'd to $HOME)
mkdir -p "$TARGET_HOME/.config/nvim/lua/config"
cp -f "$TARGET_HOME/init.lua" "$TARGET_HOME/.config/nvim/init.lua"
cp -f "$TARGET_HOME/config.lua" "$TARGET_HOME/.config/nvim/lua/config/config.lua"

# Sync LazyVim plugins
nvim --headless "+Lazy! sync" +qa || warn "LazyVim sync had issues"

# ============================================================
# Phase 11: fzf
# ============================================================

log "Phase 11/18: Installing fzf..."

if [[ ! -d "$TARGET_HOME/.fzf" ]]; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$TARGET_HOME/.fzf"
fi
"$TARGET_HOME/.fzf/install" --bin

# ============================================================
# Phase 12: Docker Engine
# ============================================================

log "Phase 12/18: Installing Docker..."

bash <(curl -sSL https://linuxmirrors.cn/docker.sh) || warn "Docker installation failed"

# Add current user to docker group
sudo usermod -aG docker "$TARGET_USER" 2>/dev/null || true

# ============================================================
# Phase 13: Podman
# ============================================================

log "Phase 13/18: Installing Podman..."

sudo apt-get install -y podman fuse-overlayfs || warn "Podman apt install failed"
podman machine init 2>&1 || warn "podman machine init failed (may need virtualization support)"

# ============================================================
# Phase 14: uv (Python Package Manager)
# ============================================================

log "Phase 14/18: Installing uv..."

curl -LsSf https://astral.sh/uv/install.sh | sh || warn "uv install failed"

# ============================================================
# Phase 14: Go
# ============================================================

GO_VERSION=1.25.5

log "Phase 15/19: Installing Go ${GO_VERSION}..."

case "$(uname -m)" in
    x86_64) GO_ARCH="amd64" ;;
    aarch64) GO_ARCH="arm64" ;;
esac
sudo rm -rf /usr/local/go
wget -q -O- "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" | sudo tar -C /usr/local -xzf -

# ============================================================
# Phase 15: Claude Code Ecosystem
# ============================================================

log "Phase 16/19: Installing Claude Code and ecosystem..."

export PATH="$TARGET_HOME/.local/bin:$PATH"

# Claude Code CLI (install.sh puts binary into ~/.claude/bin or ~/.local/bin)
curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code install failed"

# Refresh PATH so subsequent `claude` commands resolve
export PATH="$TARGET_HOME/.local/bin:$TARGET_HOME/.claude/bin:$PATH"
hash -r 2>/dev/null || true

# Plugins
for plugin in \
    "anthropics/skills" \
    "anthropics/claude-plugins-official" \
    "obra/superpowers-marketplace" \
    "OthmanAdi/planning-with-files" \
    "K-Dense-AI/claude-scientific-skills" \
    "jarrodwatts/claude-hud" \
    "kepano/obsidian-skills" \
    "affaan-m/everything-claude-code"; do
    claude plugin marketplace add "$plugin" 2>/dev/null || warn "Plugin add failed: $plugin"
done
claude plugin install superpowers@superpowers-marketplace 2>/dev/null || warn "superpowers plugin install failed"

# SuperClaude
pipx install superclaude 2>/dev/null && superclaude install || warn "superclaude install failed"

# npm global tools -> install via npm mirror in internal network

# ============================================================
# Phase 16: Modern Unix Tools
# ============================================================

log "Phase 17/19: Installing modern Unix tools..."

# gtop -> install via npm mirror in internal network

# Go-based tools
export PATH="/usr/local/go/bin:$TARGET_HOME/go/bin:$PATH"
go install github.com/rs/curlie@latest
go install github.com/charmbracelet/glow/v2@latest

# mcat
curl --proto '=https' --tlsv1.2 -LsSf \
    https://github.com/Skardyy/mcat/releases/download/v0.4.6/mcat-installer.sh | sh || warn "mcat install failed"

# mermaid-cli -> install via npm mirror in internal network

# ============================================================
# Phase 18: Google Chrome
# ============================================================

if [[ "$(uname -m)" == "x86_64" ]]; then
    log "Phase 18/19: Installing Google Chrome..."
    deb=$(mktemp)
    wget -O "$deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo dpkg -i "$deb" || sudo apt-get install -f -y
    rm -f "$deb"
else
    log "Phase 18/19: Skipping Chrome (not available for $(uname -m))"
fi

# ============================================================
# Phase 19: WSL Configuration + Internal Package List
# ============================================================

log "Phase 19/19: Finalizing WSL configuration..."

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
# Internal Network Apt Packages
# Install with:
#   sudo apt update && sudo apt install -y $(grep -v '^#' internal_apt_packages.txt | tr '\n' ' ')
#
# These packages can be installed via apt mirrors in the air-gapped network.
# Comment out or remove unavailable packages as needed.

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
scapy
tshark
mitmproxy

# Modern Unix (apt-available)
bat
fd-find
ripgrep
hyperfine
gping

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

npm install -g tree-sitter-cli
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

# ============================================================
# Summary
# ============================================================

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
echo "Post-import (inside WSL, install apt packages):"
echo "  sudo apt update"
echo "  sudo apt install -y \$(grep -v '^#' $(basename "$SCRIPT_DIR")/internal_apt_packages.txt | tr '\n' ' ')"
echo ""
echo "Post-import (install npm packages via mirror):"
echo "  bash $(basename "$SCRIPT_DIR")/internal_npm_install.sh"
echo ""
echo "Internal packages:"
echo "  apt: $SCRIPT_DIR/internal_apt_packages.txt"
echo "  npm: $SCRIPT_DIR/internal_npm_install.sh"
