#!/usr/bin/env zsh

set -euo pipefail

# Function to log installation steps
log_step() {
    echo "[INSTALL] $1"
}

# Install Zim Framework

log_step "Zimfw and plugins"

# Install Zim framework
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh

# Copy and setup dotfiles and dev utils
rsync -avvzhPi --remove-source-files /tmp/dotfiles/.config/ /root/

# Config zshrc
cat ~/.zshrc_extra >> ~/.zshrc
 
# Source zshrc and install Zim modules with error handling
source ~/.zshrc && zimfw install || echo "Zimfw installation encountered issues"

# Install gitstatus
${ZIM_HOME:-$HOME/.zim}/modules/powerlevel10k/gitstatus/install -f


# Install nvm and config node
log_step "nvm and config node version"
export NVM_DIR="$HOME/.nvm" && (
  git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
  cd "$NVM_DIR"
  git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
) && \. "$NVM_DIR/nvm.sh"

nvm install --lts && nvm use --lts

# Install Neovim
log_step "Install Neovim"

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz && rm -rf nvim-linux-x86_64.tar.gz

# Config neovim
log_step "Config Neovim"

mkdir -p "$HOME/.config/nvim"
git clone --depth=1 https://github.com/LazyVim/starter ~/.config/nvim
npm install -g tree-sitter-cli
mv "$HOME/config.lua" "$HOME/.config/nvim/lua/config/config.lua" 
mv "$HOME/init.lua" "$HOME/.config/nvim/init.lua" 
nvim --headless "+Lazy! sync" +qa

# Install Docker
log_step "Installing docker"
bash <(curl -sSL https://linuxmirrors.cn/docker.sh)

# Install fzf
log_step "Installing fzf"

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --bin


# Install uv
log_step "Installing uv"

curl -LsSf https://astral.sh/uv/install.sh | sh

# Install go
log_step "Installing go"

GO_VERSION=1.25.5
rm -rf /usr/local/go \
	&& wget -O- https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -C /usr/local -xzf -

# Install claude code and config claude code
log_step "Install claude code and config claude code"
curl -fsSL https://claude.ai/install.sh | bash
claude plugin marketplace add anthropics/skills
claude plugin marketplace add anthropics/claude-plugins-official
claude plugin marketplace add obra/superpowers-marketplace
claude plugin marketplace add OthmanAdi/planning-with-files
claude plugin marketplace add K-Dense-AI/claude-scientific-skills
claude plugin marketplace add jarrodwatts/claude-hud
claude plugin marketplace add kepano/obsidian-skills

#claude plugin install document-skills@anthropic-agent-skills
#claude plugin install example-skills@anthropic-agent-skills


pipx install superclaude && superclaude install
npm install -g @fission-ai/openspec@latest
npm install -g @musistudio/claude-code-router
npm install -g @mariozechner/claude-trace


# Install mermaid-cli
log_step "Installing mermaid-cli"
npm install -g @mermaid-js/mermaid-cli

# Install GoogleChrome
log_step "Install Google Chrome"
deb=$(mktemp) && wget -O "$deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && sudo dpkg -i "$deb" && rm "$deb"


# Install modern unix
log_step "Installing modern-unix"

## gtop
npm install gtop -g
## curlie
go install github.com/rs/curlie@latest
## glow
go install github.com/charmbracelet/glow/v2@latest

## jupyterlab
curl -LsSf https://astral.sh/uv/install.sh | sh
#mkdir -p ~/Workspaces/Utils/jupyterlab \
#	&& cd ~/Workspaces/Utils/jupyterlab \
#	&& uv venv "$HOME/.jupyter/venv" \
#	&& source "$HOME/.jupyter/venv/bin/activate" \
#	&& uv pip install jupyterlab

## jqplayground
npm install -g next
mkdir -p ~/Workspaces/Projects \
	&& cd ~/Workspaces/Projects/ \
	&& git clone --depth=1 https://github.com/jqlang/playground \
	&& cd playground \
	&& npm install \
	&& npm run build

## mcat: install first to load cargo env
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/Skardyy/mcat/releases/download/v0.4.6/mcat-installer.sh | sh
