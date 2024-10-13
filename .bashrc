#!/usr/bin/env bash

# Apply pywal colors (i.e., terminal customization tool) to new terminals
# TL;DR Diff terminal theme for each new tab opened
cat "$HOME/.cache/wal/sequences" &

# Random terminal theme each time it's opened
wal --theme random_dark -q

alias ls="ls -aGH"
alias py="python"
alias g++="/opt/homebrew/bin/g++-13"
alias gcc="/opt/homebrew/bin/gcc-13"
alias ssh-add="/usr/bin/ssh-add"
alias dac="conda deactivate"
alias make="/usr/bin/make"
alias dirname="/usr/bin/dirname"
alias readlink="/usr/bin/readlink"
alias x86="arch -x86_64 /bin/bash"

# Run wine with multiple arguments
# Execute alias `x86` (i.e. `arch -x86_64 /bin/bash`) beforehand
wine() {
  MTL_HUD_ENABLED=0 D3DM_SUPPORT_DXR=1 ROSETTA_ADVERTISE_AVX=1 WINEESYNC=1 WINEPREFIX=$HOME/Games `brew --prefix game-porting-toolkit`/bin/wine64 "$@";
}

# Launch Windows version of Steam
steam() {
    wine "C:\Program Files (x86)\Steam\steam.exe"
}

# Enable game mode
# /Applications/Xcode.app/Contents/Developer/usr/bin/gamepolicyctl game-mode set on

# Switch back to "automatic"
# /Applications/Xcode.app/Contents/Developer/usr/bin/gamepolicyctl game-mode set auto

# Wine
alias winecfg="wine winecfg"
alias regedit="wine regedit"
alias endwine="killall -9 wineserver && killall -9 wine64-preloader"

# Rewrite with "$(brew --prefix)/bin/brew"?
# Set path to default Homebrew depending on architecture type
if [[ "$(arch)" = "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
    export PATH="/usr/local/bin:${PATH}"
fi