#!/usr/bin/env bash

[[ -r "$HOME/.bash_aliases" ]] && . "$HOME/.bash_aliases"

# Apply pywal colors (i.e., terminal customization tool) to new terminals
# TL;DR Diff terminal theme for each new tab opened
cat "$HOME/.cache/wal/sequences" &

# Random dark terminal theme each time it's opened
wal --theme random_dark -q

# Run wine with multiple arguments
# Execute alias `x86` (i.e. `arch -x86_64 /bin/bash`) beforehand
wine() {
    MTL_HUD_ENABLED=1 D3DM_SUPPORT_DXR=1 ROSETTA_ADVERTISE_AVX=1 DXVK_ASYNC=1 WINEMSYNC=1 WINEESYNC=1 WINEFSYNC=1 WINEDLLOVERRIDES="dinput8=n,b;d3d11,d3d10,d3d12,dxgi=b" WINEDEBUG="-all" WINEPREFIX=$HOME/Games $(brew --prefix game-porting-toolkit)/bin/wine64 "$@";
}

# Rewrite with "$(brew --prefix)/bin/brew"?
# Set path to default Homebrew depending on architecture type
if [[ "$(arch)" = "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
    export PATH="/usr/local/bin:${PATH}"
fi

# Options: on, off, auto
game-mode() {
    /Applications/Xcode.app/Contents/Developer/usr/bin/gamepolicyctl game-mode set "$1"
}

# Options: Y, N
retina-mode() {
    WINEPREFIX=$HOME/Games $(brew --prefix game-porting-toolkit)/bin/wine64 reg add 'HKEY_CURRENT_USER\Software\Wine\Mac Driver' /v RetinaMode /t REG_SZ /d "'$1'" /f
}

# Launch Windows version of Steam
steam() {
    wine "C:\Program Files (x86)\Steam\steam.exe"
}

# Example Usage:
# v2g --src orig.mp4 --target newname --resolution 800x400 --fps 30
v2g() {
    src="" # required
    target="" # optional (defaults to source file name)
    resolution="" # optional (defaults to source video resolution)
    fps=60 # optional (defaults to 60 fps)

    while [ $# -gt 0 ]; do
        if [[ $1 == *"--"* ]]; then
                param="${1/--/}"
                declare $param="$2"
        fi
        shift
    done

    if [[ -z $src ]]; then
        echo -e "\nPlease call 'v2g --src <source video file>' to run this command\n"
        return 1
    fi

    if [[ -z $target ]]; then
        target=$src
    fi

    basename=${target%.*}
    [[ ${#basename} = 0 ]] && basename=$target
    target="$basename.gif"

    if [[ -n $fps ]]; then
        fps="-r $fps"
    fi

    if [[ -n $resolution ]]; then
        resolution="-s $resolution"
    fi

    echo "ffmpeg -i "$src" -pix_fmt rgb8 $fps $resolution "$target""
    ffmpeg -i "$src" -pix_fmt rgb8 $fps $resolution "$target"
    osascript -e "display notification \"$target successfully converted and saved\" with title \"v2g complete\""
}
