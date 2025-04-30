#!/usr/bin/env bash

# System
alias ls="ls -aGH"
alias make="/usr/bin/make"
alias dirname="/usr/bin/dirname"
alias readlink="/usr/bin/readlink"
alias nproc="sysctl -n hw.logicalcpu"

# SSH Keys
alias ssh-add="/usr/bin/ssh-add"
alias load-key="/usr/bin/ssh-add --apple-load-keychain -q"

# Programs
alias py="python"
alias dac="conda deactivate"
alias x86="arch -x86_64 /bin/bash"
alias hf="huggingface-cli"

# Wine
alias winecfg="WINEPREFIX=$HOME/Games /usr/local/bin/wine64 winecfg"
alias regedit="WINEPREFIX=$HOME/Games /usr/local/bin/wine64 regedit"
alias endwine="killall -9 wineserver && killall -9 wine64-preloader"
