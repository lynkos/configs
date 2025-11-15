#!/usr/bin/env bash

[[ -r "$HOME/.bash_aliases" ]] && . "$HOME/.bash_aliases"
[[ -r "$HOME/Scripts/gaming_funcs.sh" ]] && . "$HOME/Scripts/gaming_funcs.sh"

# Apply pywal colors (i.e., terminal customization tool) to new terminals
# TL;DR Diff terminal theme for each new tab opened
cat "$HOME/.cache/wal/sequences" &

# Random dark terminal theme each time it's opened
wal --theme random_dark -q

# Rewrite with "$(brew --prefix)/bin/brew"?
# Set path to default Homebrew depending on architecture type
if [[ "$(arch)" = "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
    export PATH="/usr/local/bin:${PATH}"
fi
