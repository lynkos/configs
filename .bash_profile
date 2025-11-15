#!/usr/bin/env bash

[[ -r "$HOME/.profile" ]] && . "$HOME/.profile"
[[ -r "$HOME/.bashrc" ]] && . "$HOME/.bashrc"
[[ -r "$HOME/Scripts/conda_funcs.sh" ]] && . "$HOME/Scripts/conda_funcs.sh"

########################### VS Code FUNCTIONS ###########################

# Auto-loads SSH key (to integrate git) for certain repos in VS Code
if [[ -n $LOAD_SSH_KEY ]]; then
    eval "$LOAD_SSH_KEY"
fi

# Auto-runs `npm run dev` for certain repos in VS Code
if [[ -n $AUTORUN_DEV ]]; then
    eval "$AUTORUN_DEV"
fi
