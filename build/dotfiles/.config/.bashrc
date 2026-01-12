export ANTHROPIC_BASE_URL=http://127.0.0.1:3456
export CLAUDE_TRACE_INCLUDE_ALL_REQUESTS=true
export ANTHROPIC_AUTH_TOKEN=sk-local-ccr-9660527

export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
export PATH="$PATH:$HOME/.fzf/bin"
export PATH="$PATH:$HOME/.local/bin"
export PATH=$PATH:/usr/local/go/bin

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

#[ -f "$HOME/.local/bin/env" ] && source "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

#export CXXFLAGS="-std=c++23 -g -fmodules-ts"
export CXXFLAGS="-std=c++23 -g"
export CXX="g++-13"

#jupyterlab
[ -f "$HOME/.jupyter/venv/bin/activate" ] && source "$HOME/.jupyter/venv/bin/activate"

alias ls='ls --classify --color=auto'
alias ll='ls -alh --classify --color=auto'
alias vim=nvim
alias vi='\vim'
alias bat=batcat
