#!/usr/bin/env bash

[[ -r "$HOME/.bash_aliases" ]] && . "$HOME/.bash_aliases"

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

########################### WINE FUNCTIONS ###########################

# Download Windows game to Steam for specific WINEPREFIX via SteamCMD
#
# dlg <WINEPREFIX_NAME> <APP_ID>
#
# E.g. `dlg DXMT 3164500`
dlg() {
   # Path containing all WINEPREFIX's
   local bottles="$HOME/Bottles"

   if [[ $# -eq 2 ]]; then
      # Get current path for later use
      local initdir="$(pwd)"

      # Path of given WINEPREFIX
      local wineprefix="$bottles/$1"
      echo "Wine prefix: '$wineprefix'"

      # Create temp directory to store download
      local temp="$wineprefix/drive_c/Program Files (x86)/Steam/steamapps/temp/$2"
      mkdir -p "$temp"
      echo "Temporarily storing download in 'C:\\Program Files (x86)\\Steam\\steamapps\\temp\\$2'"

      # Cleanup logic in case something goes wrong
      trap "echo 'Something went wrong; performing cleanup...'; rm -rf '$temp'; trap - EXIT ERR; echo 'Cleanup complete. Exiting...'; cd '$initdir'" EXIT ERR

      # Enter SteamCMD directory
      cd "$HOME/SteamCMD"

      # Steam username
      local steam_user="STEAM_USERNAME"

      # Download game
      ./steamcmd.sh +@sSteamCmdForcePlatformType windows +force_install_dir "$temp" +login "$steam_user" +app_update "$2" validate +quit

      # Get directory installation name from its appmanifest
      local dirname="$(sed -n 's/^[[:space:]]*"installdir"[[:space:]]*"\([^"]*\)".*/\1/p' "$temp/steamapps/appmanifest_$2.acf")"
      echo "Directory name of downloaded game is: $dirname"

      # Move and rename downloaded directory into common
      mv "$temp" "$wineprefix/drive_c/Program Files (x86)/Steam/steamapps/common/$dirname"
      echo "Moved and renamed game from 'C:\\Program Files (x86)\\Steam\\steamapps\\temp\\$2' to 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\$dirname'"

      # Go to appmanifest(s) (i.e. .acf file(s))
      cd "$wineprefix/drive_c/Program Files (x86)/Steam/steamapps/common/$dirname/steamapps"

      # Move appmanifest(s) into parent `steamapps` so Steam recognizes game is installed
      mv *.acf ../../../
      echo "Moved downloaded appmanifest(s) from 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\$dirname\\steamapps' to 'C:\\Program Files (x86)\\Steam\\steamapps'"

      # Go back to initial directory
      cd "$initdir"

      # Reset (i.e. re-enable default processing of) signal
      trap - EXIT ERR

      # TODO: (OPTIONAL) If child `steamapps` ONLY contains empty dirs (i.e. basically empty)...
      # if [[ "$(/bin/ls -A | wc -l)" -eq "$(find . -maxdepth 1 -type d | wc -l)" ]]; then
         # ... then delete it
         # cd ../
         # rm -r steamapps
         # echo "Removed 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\$dirname\\steamapps' since no longer needed"
      # fi
      
   else
      echo "ERROR: Invalid number of args. Must include:"
      echo "	* Name of WINEPREFIX (i.e. $(/bin/ls --color=always -dm $bottles/*/ | tr -d '\n' | sed "s|$bottles/||g"))"
      printf '	* Steam App ID of game (find at \e]8;;https://steamdb.info\e\\SteamDB.info\e]8;;\e\\)\n'
   fi
}

# Move Steam game from one Wine prefix (e.g. DXMT, DXVK, GPTk, etc.) to another
#
# mvdlg <APP_ID> <SOURCE_PREFIX> <TARGET_PREFIX>
# E.g. `mvdlg 2623190 DXMT2 GPTk`
mvdlg() {
   # Path containing all WINEPREFIX's
   local bottles="$HOME/Bottles"

   if [[ $# -eq 3 ]]; then
      # Path of source WINEPREFIX
      local source="$bottles/$2"
      echo "Source Wine prefix: '$source'"

      # Path of target WINEPREFIX
      local target="$bottles/$3"
      echo "Target Wine prefix: '$target'"
      
      # Get directory installation name from its appmanifest
      local dirname="$(sed -n 's/^[[:space:]]*"installdir"[[:space:]]*"\([^"]*\)".*/\1/p' "$source/drive_c/Program Files (x86)/Steam/steamapps/appmanifest_$1.acf")"
      echo "Directory name of game with App ID '$1' is: '$dirname'"

      # Move game directory from source to target 
      mv "$source/drive_c/Program Files (x86)/Steam/steamapps/common/$dirname" "$target/drive_c/Program Files (x86)/Steam/steamapps/common/$dirname"
      echo "Moved game in 'C:\\Program Files (x86)\\Steam\\steamapps\\common\\$dirname' from '$source' to '$target'"

      # Move app manifest from source to target 
      mv "$source/drive_c/Program Files (x86)/Steam/steamapps/appmanifest_$1.acf" "$target/drive_c/Program Files (x86)/Steam/steamapps/appmanifest_$1.acf"
      echo "Moved 'appmanifest_$1.acf' in 'C:\\Program Files (x86)\\Steam\\steamapps' from '$source' to '$target'"

   else
      echo "ERROR: Invalid number of args. Must include:"
      printf '	* Steam App ID of game (find at \e]8;;https://steamdb.info\e\\SteamDB.info\e]8;;\e\\)\n'
      echo "	* Name of source WINEPREFIX to move downloaded game from (i.e. $(/bin/ls --color=always -dm $bottles/*/ | tr -d '\n' | sed "s|$bottles/||g"))"
      echo "	* Name of target WINEPREFIX to move downloaded game to (i.e. $(/bin/ls --color=always -dm $bottles/*/ | tr -d '\n' | sed "s|$bottles/||g"))"
   fi
}

# Quit/stop a specific Wine prefix (e.g. DXMT, DXVK, GPTk, etc.)
#
# endwine <NAME_OF_PREFIX>
# E.g. `endwine DXMT`
endwine() {
   # Path containing all WINEPREFIX's
   local bottles="$HOME/Bottles"

   if [[ $# -eq 1 ]]; then
      WINEPREFIX="$bottles/$1" wineserver -kw
      
   else
      echo "ERROR: Invalid number of args. Specify name of ONE (1) bottle to kill ($(/bin/ls --color=always -dm $bottles/*/ | tr -d '\n' | sed "s|$bottles/||g"))."
   fi
}

# Run wine with multiple arguments
# Execute alias `x86` (i.e. `arch -x86_64 /bin/bash`) beforehand
wine-gptk() {
    local winepath="$HOME/Wine/3.0b2-gptk"

    MTL_HUD_ENABLED=1 D3DM_SUPPORT_DXR=1 ROSETTA_ADVERTISE_AVX=1 D3DM_ENABLE_METALFX=0 WINEARCH=win64 WINEESYNC=1 WINEDEBUG=-all PATH="$winepath/bin:$PATH" WINELOADER="$winepath/bin/wine64-preloader" WINEDLLPATH="$winepath/lib/wine" WINESERVER="$winepath/bin/wineserver" LD_LIBRARY_PATH="$winepath/lib:$LD_LIBRARY_PATH" DYLD_FALLBACK_LIBRARY_PATH="/usr/lib:$DYLD_FALLBACK_LIBRARY_PATH" WINE="$winepath/bin/wine64" WINEPREFIX=$HOME/Bottles/GPTk "$winepath/bin/wine64" "$@"; # WINEDLLOVERRIDES="dinput8=n,b;d3d12,d3d11,d3d10,dxgi=b"
}

wine-dxmt() {
    local winepath="$HOME/Wine/10.12-dxmt"

    MTL_HUD_ENABLED=1 D3DM_SUPPORT_DXR=1 ROSETTA_ADVERTISE_AVX=1 D3DM_ENABLE_METALFX=0 WINEARCH=win64 WINEESYNC=1 WINEDEBUG=-all PATH="$winepath/bin:$PATH" WINELOADER="$winepath/bin/wine" WINEDLLPATH="$winepath/lib/wine" WINESERVER="$winepath/bin/wineserver" LD_LIBRARY_PATH="$winepath/lib:$LD_LIBRARY_PATH" DYLD_FALLBACK_LIBRARY_PATH="/usr/lib:$DYLD_FALLBACK_LIBRARY_PATH" WINE="$winepath/bin/wine" WINEPREFIX=$HOME/Bottles/DXMT2 "$winepath/bin/wine" "$@"; # WINEDLLOVERRIDES="dinput8=n,b;d3d12,d3d11,d3d10,dxgi=b"
}

# Launch Windows version of Steam
steam() {
    wine-dxmt "C:\Program Files (x86)\Steam\steam.exe"
}

########################### GAMING FUNCTIONS ###########################

# Options: on, off, auto
game-mode() {
    /Applications/Xcode.app/Contents/Developer/usr/bin/gamepolicyctl game-mode set "$1"
}

# Enable retina mode for Windows gaming
retina-on() {
    wine-dxmt reg add 'HKEY_CURRENT_USER\Software\Wine\Mac Driver' /v 'RetinaMode' /t REG_SZ /d 'Y' /f
    wine-dxmt reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /v 'LogPixels' /t REG_DWORD /d 192 /f # = (96 * 3024 / 1512). Prev: 216.
}

# Disable retina mode for Windows gaming
retina-off() {
    wine-dxmt reg add 'HKEY_CURRENT_USER\Software\Wine\Mac Driver' /v 'RetinaMode' /t REG_SZ /d 'N' /f
    wine-dxmt reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /v 'LogPixels' /t REG_DWORD /d 96 /f # 96dpi = 100%
}

########################### FFMPEG FUNCTION ###########################

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
