#!/bin/sh

export PATH="$PATH:/Library/Frameworks/Python.framework/Versions/Current/bin:$HOME/Library/Python/3.12/bin:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin"

# Path to terminal theme (i.e. Pywal)
export PATH="${PATH}:$HOME/Library/Python/3.12/lib/python/site-packages"

# For newest bash version
export PATH="$(brew --prefix)/bin:$PATH"

# Rust & Cargo
. "$HOME/.cargo/env"

# Manual terminal color customization
PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS="exfxfeaeBxxehehbadacea"

export HOMEBREW_NO_ENV_HINTS=1
export LD_LIBRARY_PATH="/usr/local/lib"
export CONDA_AUTO_ACTIVATE_BASE=false
export SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
export NVM_DIR="$HOME/.nvm"

# Load nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Load SSH keys
ssh-load() {
    /usr/bin/ssh-add --apple-load-keychain -q
}

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('$HOME/miniconda3/bin/conda' 'shell.sh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="$HOME/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Ruby
source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
source /opt/homebrew/opt/chruby/share/chruby/auto.sh
chruby ruby-3.4.1
