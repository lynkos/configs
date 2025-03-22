#!/usr/bin/env bash

alias ls="ls -aGH"
alias py="python"
alias ssh-add="/usr/bin/ssh-add"
alias dac="conda deactivate"
alias make="/usr/bin/make"
alias dirname="/usr/bin/dirname"
alias readlink="/usr/bin/readlink"
alias x86="arch -x86_64 /bin/bash"

# Wine
alias winecfg="`brew --prefix game-porting-toolkit`/bin/wine64 winecfg"
alias regedit="`brew --prefix game-porting-toolkit`/bin/wine64 regedit"
alias endwine="killall -9 wineserver && killall -9 wine64-preloader"
