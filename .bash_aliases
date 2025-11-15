#!/usr/bin/env bash

# System
alias ls="ls -aGHl --color=always"
alias make="/usr/bin/make"
alias dirname="/usr/bin/dirname"
alias readlink="/usr/bin/readlink"
alias nproc="sysctl -n hw.ncpu" # OR hw.logicalcpu
alias fl="file *"
alias tree="tree --noreport"
alias cptree="tree | pbcopy"
alias cache="$(getconf DARWIN_USER_CACHE_DIR)"
alias stash="git stash"
alias pop="git stash pop"

# SSH Keys
alias ssh-add="/usr/bin/ssh-add"
alias ssh-load="/usr/bin/ssh-add --apple-load-keychain -q"

# Programs
alias py="python"
alias dac="conda deactivate"
alias x86="arch -x86_64 /bin/bash"
alias hf="huggingface-cli"

# Wine
alias killwine="killall -9 wineserver && killall -9 wine64-preloader && killall -9 wine"
alias winecfg="wine winecfg"
alias regedit="wine regedit"
