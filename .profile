#!/bin/sh

export PATH="$PATH:/Library/Frameworks/Python.framework/Versions/Current/bin:$HOME/Library/Python/3.12/bin"

# Manual terminal color customization
PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "
export CLICOLOR=1
export LSCOLORS="exfxfeaeBxxehehbadacea"

export HOMEBREW_NO_ENV_HINTS=1
export LD_LIBRARY_PATH="/usr/local/lib"
export CONDA_AUTO_ACTIVATE_BASE=false
export SSH_KEY_PATH="$HOME/.ssh/id_ed25519"

# Auto-loads SSH key for specific repos in VS Code (git)
if [[ -n $LOAD_SSH_KEY ]]; then
    eval "$LOAD_SSH_KEY"
fi

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
