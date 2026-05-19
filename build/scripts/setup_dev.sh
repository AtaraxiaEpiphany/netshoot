#!/usr/bin/env bash
#
# Minimal WSL2 Development Environment Setup
#
# Installs common dev toolchains: C/C++, Java/Maven, Python, Node.js, Go
#
# Usage:
#   bash build/scripts/setup_dev.sh            # Run / Resume
#   bash build/scripts/setup_dev.sh --reset    # Clear checkpoint and restart
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

MIRROR_SOURCE="${MIRROR_SOURCE:-mirrors.aliyun.com}"
TARGET_USER="${WSL_USER:-tulip}"

# Support root execution (Docker test)
if [[ "$(id -u)" -eq 0 ]]; then
    sudo() {
        if [[ "$1" == *=* ]]; then env "$@"; else "$@"; fi
    }
    if ! id "$TARGET_USER" &>/dev/null; then
        useradd -s /usr/bin/fish -m "$TARGET_USER"
        usermod -aG sudo "$TARGET_USER"
        echo "$TARGET_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$TARGET_USER"
        chmod 440 "/etc/sudoers.d/$TARGET_USER"
    fi
fi
TARGET_HOME="$(eval echo "~$TARGET_USER")"
export HOME="$TARGET_HOME"

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
esac

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "\n${GREEN}[SETUP]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ============================================================
# Checkpoint System
# ============================================================

CHECKPOINT_FILE="${CHECKPOINT_FILE:-$TARGET_HOME/.wsl_setup_checkpoint}"

TOTAL_PHASES=7

phase() {
    local num=$1
    local desc="$2"
    if grep -q "^phase_${num}=done$" "$CHECKPOINT_FILE" 2>/dev/null; then
        log "Phase ${num}/${TOTAL_PHASES}: ${desc} ${CYAN}[CACHED]${NC}"
        return 1
    fi
    log "Phase ${num}/${TOTAL_PHASES}: ${desc}"
    return 0
}

phase_done() {
    echo "phase_${1}=done" >> "$CHECKPOINT_FILE"
}

if [[ -f "$CHECKPOINT_FILE" ]]; then
    cached=$(grep -c '=done$' "$CHECKPOINT_FILE" 2>/dev/null || echo 0)
    if [[ "$cached" -gt 0 ]]; then
        log "Resuming from checkpoint ($cached/${TOTAL_PHASES} phases cached)"
    fi
fi

# ============================================================
# Phase 1: System Packages
# ============================================================

if phase 1 "Installing system packages..."; then

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates curl wget jq software-properties-common

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

sudo add-apt-repository universe
sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    `# --- C / C++ ---` \
    build-essential gcc g++ clang cmake make valgrind gdb \
    \
    `# --- Java / Maven ---` \
    openjdk-21-jdk maven \
    \
    `# --- Python ---` \
    python3 python3-pip python3-dev python3-venv python3-setuptools pipx \
    \
    `# --- Shell / Editor ---` \
    fish vim tmux git \
    \
    `# --- Utilities ---` \
    curl wget jq tree rsync unzip zip sudo locales

phase_done 1
fi

# ============================================================
# Phase 2: Locale
# ============================================================

if phase 2 "Setting up locale..."; then

sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

phase_done 2
fi

# ============================================================
# Phase 3: Default Shell
# ============================================================

if phase 3 "Setting fish as default shell..."; then

sudo chsh -s "$(which fish)" "$TARGET_USER"

phase_done 3
fi

# ============================================================
# Phase 4: nvm + Node.js
# ============================================================

if phase 4 "Installing nvm and Node.js LTS..."; then

export NVM_DIR="$TARGET_HOME/.nvm"
if [[ ! -d "$NVM_DIR" ]]; then
    git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
    (cd "$NVM_DIR" && git checkout "$(git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1))")
fi
set +u
. "$NVM_DIR/nvm.sh"
nvm install --lts && nvm use --lts
set -u

phase_done 4
fi

# ============================================================
# Phase 5: Go
# ============================================================

if phase 5 "Installing Go..."; then

GO_VERSION=1.26.3

case "$(uname -m)" in
    x86_64) GO_ARCH="amd64" ;;
    aarch64) GO_ARCH="arm64" ;;
esac
sudo rm -rf /usr/local/go
wget -q -O- "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" | sudo tar -C /usr/local -xzf -

log "  Go ${GO_VERSION} installed to /usr/local/go"

phase_done 5
fi

# ============================================================
# Phase 6: uv (Python Package Manager)
# ============================================================

if phase 6 "Installing uv..."; then

curl -LsSf https://astral.sh/uv/install.sh | sh || warn "uv install failed"

phase_done 6
fi

# ============================================================
# Phase 7: WSL Configuration
# ============================================================

if phase 7 "Finalizing configuration..."; then

sudo tee /etc/wsl.conf > /dev/null <<EOF
[user]
default=$TARGET_USER

[network]
hostname=devbox

[interop]
appendWindowsPath=false

[environment]
TERM=xterm
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8
EOF

sudo chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME"

phase_done 7
fi

# ============================================================
# Cleanup & Summary
# ============================================================

rm -f "$CHECKPOINT_FILE"

echo ""
echo "========================================="
echo "  Dev Environment Setup Complete!"
echo "========================================="
echo ""
echo "Installed:"
echo "  C/C++    : gcc, g++, clang, cmake, make"
echo "  Java     : openjdk-21, maven"
echo "  Python   : python3, pip, venv, uv"
echo "  Node.js  : nvm + LTS (via nvm use --lts)"
echo "  Go       : $(go version 2>/dev/null || echo '/usr/local/go')"
echo "  Shell    : fish"
echo ""
echo "Next steps:"
echo "  wsl --export <distro> devbox.tar"
echo "  wsl --import devbox <path> devbox.tar"
