#!/usr/bin/env bash

############################################################################
#                             gaming_funcs.sh                              #
#                                                                          #
#              Bash functions for playing Windows games on Mac             #
# ------------------------------------------------------------------------ #
# Setup:                                                                   #
#    1. Switch architecture                                                #
#       `arch -x86_64 /bin/bash`                                           #
#    2. Set up Wine environment                                            #
#       `set-wine <variant>`                                               #
#                                                                          #
# Usage:                                                                   #
#    *  Download Windows Steam game to Wine prefix via SteamCMD            #
#       `dlg <WINEPREFIX_NAME> <APP_ID>`                                   #
#    *  Move Windows Steam game between Wine prefixes                      #
#       `mvdlg <APP_ID> <SOURCE_WINEPREFIX_NAME> <TARGET_WINEPREFIX_NAME>` #
#    *  Install Windows Steam into specific Wine prefix                    #
#       `instm <WINEPREFIX_NAME>`                                          #
#    *  Quit/stop a specific Wine prefix                                   #
#       `endwine <WINEPREFIX_NAME>`                                        #
#    *  Run Wine with multiple arguments                                   #
#       `wine <program> [args...]`                                         #
#    *  Launch Windows version of Steam                                    #
#       `steam`                                                            #
#    *  Set retina mode for Windows gaming via Wine (Options: on, off)     #
#       `retina <OPTION>`                                                  #
#    *  Set macOS Game Mode (Options: on, off, auto)                       #
#       `game-mode <OPTION>`                                               #
#    *  Clear Oblivion Remastered shader cache (used for debugging)        #
#       `clear-cache`                                                      #
#    *  Enable font smoothing (i.e. anti-aliasing)                         #
#       `anti-alias`                                                       #
#    *  Configure settings for Far Cry 3, then launch Steam                #
#       `fc3`                                                              #
#                                                                          #
# Examples:                                                                #
#    ```                                                                   #
#    arch -x86_64 /bin/bash                                                #
#    set-wine gptk                                                         #
#    instm GPTk                                                            #
#    dlg GPTk 3164500                                                      #
#    wine winecfg                                                          #
#    retina on                                                             #
#    game-mode on                                                          #
#    mvdlg 3164500 GPTk DXMT                                               #
#    set-wine dxmt                                                         #
#    steam                                                                 #
#    endwine DXMT                                                          #
#    ```                                                                   #
# ------------------------------------------------------------------------ #
#                      https://gist.github.com/lynkos                      #
############################################################################

############################### CONSTANTS ##################################

# Print debug messages to console and stderr
ENABLE_DEBUG=1

# Base directories
readonly WINE_DIR="$HOME/Wine"
readonly BOTTLES_DIR="$HOME/Bottles"

# Uncomment for logging
# readonly LOG_DIR="$HOME/Logs"

# Resolution
readonly WIDTH=3024 # pixels (px)
readonly FORMULA_WIDTH=1512 # pixels (px)
readonly FORMULA_DPI=96 # 96dpi = 100% scaling in Windows
readonly DPI=$(printf '%.0f' $(bc -l <<< "scale=2; $FORMULA_DPI * $WIDTH / $FORMULA_WIDTH")) # 192 = ($FORMULA_DPI * $WIDTH / $FORMULA_WIDTH)

# Previous DPI: 216dpi
#
# Previous formula:
# readonly DIAGONAL=14.2 # inches (in)
# readonly HEIGHT=1964 # pixels (px)
# $(echo "scale=0; dpi = sqrt($WIDTH^2 + $HEIGHT^2) / $DIAGONAL; dpi / 1" | bc -l)
#
# Manually calc DPI: https://dpi.lv

# Steam
readonly STEAM_USER="anonymous"
readonly STEAMCMD_DIR="$HOME/SteamCMD"
readonly STEAMAPPS_DIR="drive_c/Program Files (x86)/Steam/steamapps"
readonly STEAMAPPS_DIR_WIN="C:\\Program Files (x86)\\Steam\\steamapps" # Double backslash since this var will only be used for printing (e.g. echo "$STEAMAPPS_DIR_WIN\\common")

# Print options
# FIXME: Rewrite to avoid `cd` error
readonly BOTTLES="$(init_dir=$(pwd) && cd $BOTTLES_DIR && /bin/ls --color=always -1d */ | sed 's|/||' | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g' && cd $init_dir)"
readonly VARIANTS="$(init_dir=$(pwd) && cd $WINE_DIR && /bin/ls --color=always -1d */ | sed 's|/||' | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g' && cd $init_dir)"

############################## WINE FUNCTIONS ##############################

# Set up Wine environment for a specific variant
# Execute alias `x86` (i.e. `arch -x86_64 /bin/bash`) beforehand
#
# set-wine <variant>
# E.g. `set-wine gptk`
set-wine() {
    local variant="$1"

    # Verify Wine variant
    if [[ -z "$variant" ]]; then
        _info "Usage: set-wine <variant>" >&2
        _info "Available variants: $VARIANTS" >&2
        return 1
    fi

    # Clear prev set, shared Wine env vars for clean transitions when switching between variants
    # No sense in clearing env vars used by only ONE (1) Wine variant (aka are unique to a single variant), since there wouldn't be any conflicting configs/settings to worry about
    unset MTL_HUD_ENABLED WINEESYNC WINEMSYNC WINEDLLOVERRIDES WINE_LARGE_ADDRESS_AWARE MVK_CONFIG_RESUME_LOST_DEVICE # WINECPUMASK

    # TODO: End all currently running instances of Wine
    
    # Env vars shared across all Wine variants
    export ROSETTA_ADVERTISE_AVX=1
    export WINEARCH=win64 # 64-bit Wine architecture
    export WINEDEBUG=-all # Disable Wine debugging/logging # "+heap,+timestamp,+module,+pid,+relay,+snoop,+fps,+debugstr,+threadname,+seh,+memory,+d3dm"

    # MoltenVK env vars; used by all Wine variants (since they're built with MoltenVK support)
    # https://github.com/KhronosGroup/MoltenVK/blob/main/Docs/MoltenVK_Configuration_Parameters.md
    export MVK_CONFIG_TRACE_VULKAN_CALLS=0 # No Vulkan call logging
    export MVK_CONFIG_DEBUG=0 # Disable debugging
    export MVK_CONFIG_LOG_LEVEL=0 # No logging
    
    # Wine variant-specific configs
    case "$variant" in
        # Game Porting Toolkit
        "gptk")
            local winename="Game Porting Toolkit"
            local variant_version="2.1"
            local winepath="$WINE_DIR/gptk/2_1"
            local wine_executable="wine64"
            local wine_preloader="wine64-preloader"
            local wineprefix="$BOTTLES_DIR/GPTk"

            export MTL_HUD_ENABLED=1
            export D3DM_SUPPORT_DXR=1
            export D3DM_ENABLE_METALFX=0 # If `D3DM_ENABLE_METALFX=1`, set `WINEESYNC=0`
            export WINEESYNC=1 # `0` if `D3DM_ENABLE_METALFX=1` else `1`
            export WINEDLLOVERRIDES="dinput8=n,b;d3d12,d3d11,d3d10,dxgi=b" # "winemenubuilder.exe=d"
            ;;

        # DirectX-Metal
        "dxmt")
            local winename="DirectX-Metal"
            local variant_version="v0.71"
            local winepath="$WINE_DIR/dxmt/latest"
            local wine_executable="wine"
            local wine_preloader="wine"
            local wineprefix="$BOTTLES_DIR/DXMT"

            export MTL_HUD_ENABLED=1
            export DXMT_METALFX_SPATIAL_SWAPCHAIN=0
            export DXMT_CONFIG_FILE="$WINE_DIR/dxmt/dxmt.conf"
            #export DXMT_CONFIG="d3d11.preferredMaxFrameRate=60;d3d11.metalSpatialUpscaleFactor=2.0;" # Alternative to DXMT_CONFIG_FILE
            export DXMT_LOG_LEVEL=none
            export DXMT_LOG_PATH=none # "$winepath/logs"
            export DXMT_ENABLE_NVEXT=0
            export WINEMSYNC=0
            export WINEDLLOVERRIDES="dinput8=n,b;d3d11,d3d10core,dxgi=b" # winemenubuilder.exe=d
            #export MTL_SHADER_VALIDATION=0
            #export MTL_DEBUG_LAYER=0
            #export MTL_CAPTURE_ENABLED=0
            ;;

        # DirectX-Vulkan
        "dxvk")
            local winename="DirectX-Vulkan"
            local variant_version="v1.10.3-20230507-repack"
            local winepath="$WINE_DIR/dxvk/10.14"
            local wine_executable="wine"
            local wine_preloader="wine"
            local wineprefix="$BOTTLES_DIR/DXVK"

            export DXVK_HUD=full
            export DXVK_ASYNC=1
            export DXVK_STATE_CACHE=1
            export DXVK_CONFIG_FILE="$WINE_DIR/dxvk/dxvk.conf"
            export DXVK_LOG_LEVEL=none
            export DXVK_LOG_PATH=none
            export MVK_CONFIG_RESUME_LOST_DEVICE=1
            export WINE_LARGE_ADDRESS_AWARE=1
            export WINEDLLOVERRIDES="d3d11,d3d10core,dinput8=n,b" # "d3d11,d3d10core,d3d9,dxgi,dinput8=n,b"
            ;;

        # CrossOver
        "crossover")
            local winename="CrossOver"
            local variant_version="v23.7.1"
            local winepath="$WINE_DIR/crossover/23.7.1"
            local wine_executable="wine64" # "wine"
            local wine_preloader="wine64-preloader" # "wine-preloader"
            local wineprefix="$BOTTLES_DIR/CrossOver"

            export MTL_HUD_ENABLED=1
            export WINEESYNC=1
            # export WINEDLLOVERRIDES="dinput8=n,b;d3d12,d3d11,d3d10,dxgi=b"
            ;;

        *)
            _err "Unknown variant '$variant'" >&2
            echo "Valid variants: $VARIANTS" >&2
            return 1
            ;;
    esac
    
    # Set up Wine env paths and executables
    export PATH="$winepath/bin:$PATH"
    export WINELOADER="$winepath/bin/$wine_preloader"
    export WINEDLLPATH="$winepath/lib/wine"
    export WINESERVER="$winepath/bin/wineserver"
    export LD_LIBRARY_PATH="$winepath/lib:$LD_LIBRARY_PATH"
    export DYLD_FALLBACK_LIBRARY_PATH="/usr/lib:$DYLD_FALLBACK_LIBRARY_PATH"
    export WINE="$winepath/bin/$wine_executable"
    export WINEPREFIX="$wineprefix"
    export WINE_VERSION="$(_wine_version)"
    export VARIANT_ID="$variant"
    export VARIANT_NAME="$winename"
    export VARIANT_VERSION="$variant_version"

    _info "$winename translation environment successfully set!" >&2
    echo -e "\nUsage:" >&2
    echo -e "       wine <program> [args...]\n" >&2
    _wine_info
}

# Download Windows game to Steam for specific WINEPREFIX via SteamCMD
#
# dlg <WINEPREFIX_NAME> <APP_ID>
#
# E.g. `dlg DXMT 3164500`
dlg() {
   if [[ $# -eq 2 ]]; then
      # Get current path for later use
      local initdir="$(pwd)"

      # Assign user input to variable for better readability
      local app_id="$2"
      _dbug "Given app ID: '$app_id'"

      # Path of given WINEPREFIX
      local wineprefix="$BOTTLES_DIR/$1"
      _dbug "Given Wine prefix: '$wineprefix'"

      # Create temp directory to store download
      local temp="$wineprefix/$STEAMAPPS_DIR/temp/$app_id"
      mkdir -p "$temp"
      _dbug "Temporarily storing download in '$STEAMAPPS_DIR_WIN\\temp\\$app_id'"

      # Cleanup logic in case something goes wrong
      trap "_err 'Something went wrong. Exiting...'; cd '$initdir'; return 1;" EXIT ERR

      # Enter SteamCMD directory
      cd "$STEAMCMD_DIR"

      # Download game
      ./steamcmd.sh +@sSteamCmdForcePlatformType windows +force_install_dir "$temp" +login "$STEAM_USER" +app_update "$app_id" validate +quit

      # Get appmanifest path
      local app_manifest="$temp/steamapps/appmanifest_$app_id.acf"
      _dbug "Appmanifest: '$app_manifest'"

      # Get directory installation name from appmanifest
      local dirname="$(sed -n 's/^[[:space:]]*"installdir"[[:space:]]*"\([^"]*\)".*/\1/p' "$app_manifest")"
      _dbug "Directory name of downloaded game is: $dirname"

      # Get game size from appmanifest (i.e. value for app ID key)
      local size_on_disk="$(sed -n 's/^[[:space:]]*"SizeOnDisk"[[:space:]]*"\([^"]*\)".*/\1/p' "$app_manifest")"
      _dbug "Disk size of $dirname is: $size_on_disk"

      # TODO: If directory already exists, overwrite (or delete) it, else it'll exit; same with the upcoming directories

      # Move and rename downloaded directory into common
      mv "$temp" "$wineprefix/$STEAMAPPS_DIR/common/$dirname"
      _dbug "Moved and renamed game from '$STEAMAPPS_DIR_WIN\\temp\\$app_id' to '$STEAMAPPS_DIR_WIN\\common\\$dirname'"

      # Go to appmanifest(s) (i.e. .acf file(s))
      cd "$wineprefix/$STEAMAPPS_DIR/common/$dirname/steamapps"

      # Move appmanifest(s) into parent steamapps so Steam recognizes game is installed
      mv *.acf ../../../
      _dbug "Moved downloaded appmanifest(s) from '$STEAMAPPS_DIR_WIN\\common\\$dirname\\steamapps' to '$STEAMAPPS_DIR_WIN'"

      # TODO: Delete child steamapps IFF empty or only contains empty dirs

      # Go into parent steamapps
      cd ../../../

      # Register game in libraryfolders.vdf
      _update_library_vdf "$app_id" "$size_on_disk"
      _dbug "Registered game in '$STEAMAPPS_DIR_WIN\\libraryfolders.vdf'"

      # Go back to initial directory
      cd "$initdir"

      # Reset (i.e. re-enable default processing of) signal
      trap - EXIT ERR
      
   else
      _err "Invalid number of args. Must include:"
      echo "       * Name of WINEPREFIX (i.e. $BOTTLES)" >&2
      printf '       * Steam App ID of game (find at \e]8;;https://steamdb.info\e\\SteamDB.info\e]8;;\e\\)\n' >&2
   fi
}

# Move Steam game from one Wine prefix (e.g. DXMT, DXVK, GPTk, CrossOver, etc.) to another
#
# mvdlg <APP_ID> <SOURCE_WINEPREFIX_NAME> <TARGET_WINEPREFIX_NAME>
# E.g. `mvdlg 2623190 DXMT GPTk`
#
# TODO: Update `libraryfolders.vdf` (in BOTH bottles) after moving game
mvdlg() {
   if [[ $# -ne 3 ]]; then
      _err "Invalid number of args. Must include:"
      printf '       * Steam App ID of game (find at \e]8;;https://steamdb.info\e\\SteamDB.info\e]8;;\e\\)\n' >&2
      echo "       * Name of source WINEPREFIX to move downloaded game from (i.e. $BOTTLES)" >&2
      echo "       * Name of target WINEPREFIX to move downloaded game to (i.e. $BOTTLES)" >&2
      return 1
   fi

   # Source WINEPREFIX path
   local source="$BOTTLES_DIR/$2"

   # Confirm source WINEPREFIX exists
   if [[ ! -d "$source" ]]; then
      _err "Source WINEPREFIX does not exist: '$source'"
      return 1
   fi
   _dbug "Source WINEPREFIX: '$source'"

   # Target WINEPREFIX path
   local target="$BOTTLES_DIR/$3"

   # Confirm target WINEPREFIX exists
   if [[ ! -d "$target" ]]; then
      _err "Target WINEPREFIX does not exist: '$target'"
      return 1
   fi
   _dbug "Target WINEPREFIX: '$target'"

   # Given Steam game's app ID
   local app_id="$1"
   _dbug "Steam App ID: $app_id"

   # Path to source appmanifest
   local manifest="$source/$STEAMAPPS_DIR/appmanifest_$app_id.acf"
   
   # Confirm source appmanifest exists
   if [[ ! -f "$manifest" ]]; then
      _err "Source appmanifest not found: '$manifest'"
      return 1
   fi
   _dbug "Source appmanifest: '$manifest'"

   # Get directory installation name from appmanifest
   local dirname="$(sed -n 's/^[[:space:]]*"installdir"[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest")"

   # Confirm directory installation name exists
   if [[ -z "$dirname" ]]; then
      _err "Failed to extract install directory '$dirname' from '$manifest'"
      return 1
   fi
   _dbug "Steam game: $dirname"

   # Path to the game directory in source
   local source_dir="$source/$STEAMAPPS_DIR/common/$dirname"
   
   # Confirm game directory exists in source
   if [[ ! -d "$source_dir" ]]; then
      _err "Game directory not found: '$source_dir'"
      return 1
   fi

   # Path to the target game directory
   local target_dir="$target/$STEAMAPPS_DIR/common/$dirname"
   
   # Ensure target common directory exists
   mkdir -p "$target/$STEAMAPPS_DIR/common"

   # Move game directory from source to target
   if ! mv "$source_dir" "$target_dir"; then
      _err "Failed to move game in '$STEAMAPPS_DIR_WIN\\common\\$dirname' from '$source' to '$target'"
      return 1
   fi
   _dbug "Moved game in '$STEAMAPPS_DIR_WIN\\common\\$dirname' from '$source' to '$target'"

   # Target appmanifest location
   local target_manifest="$target/$STEAMAPPS_DIR/appmanifest_$app_id.acf"
   
   # Move app manifest from source to target
   if ! mv "$manifest" "$target_manifest"; then
      _err "Failed to move appmanifest from '$manifest' to '$target_manifest'"
      _err "For Steam to recognize the game, you will need to [manually] move it yourself"
      return 1
   fi
   _dbug "Moved 'appmanifest_$app_id.acf' in '$STEAMAPPS_DIR_WIN' from '$source' to '$target'"

   _info "Moved '$dirname' (App ID '$app_id') from '$source' to '$target'"
   return 0
}

# Install Steam for specific Wine prefix
# instm <WINEPREFIX_NAME>
# 
# E.g. `instm DXVK`
instm() {
   if [[ $# -eq 1 ]]; then
      # Create temporary file for downloaded Windows Steam installer
      local temp_file="$(mktemp -t SteamSetup)"

      # Cleanup logic in case there's an issue
      trap "_err 'Something went wrong; performing cleanup...'; rm -rf $temp_file; trap - EXIT ERR; _info 'Cleanup complete. Exiting...'" EXIT ERR
    
      # Download SteamSetup.exe (i.e. Windows Steam installer)
      if ! curl -o "$temp_file" https://cdn.fastly.steamstatic.com/client/installer/SteamSetup.exe; then
         _err "Failed to download Steam installer"
         # Reset (i.e. re-enable default processing of) signal(s) before exiting
         trap - EXIT ERR
         return 1
      fi

      _dbug "Downloaded Steam installer to '$temp_file'"

      # Install Windows Steam for WINEPREFIX
      WINEPREFIX="$BOTTLES_DIR/$1" "$WINE" "$temp_file"
      _info "Installed Steam in $BOTTLES_DIR/$1"

      # Delete temporary Windows Steam installer
      rm -f "$temp_file"
      _dbug "Deleted temporary Windows Steam installer in '$temp_file'"

      # Reset (i.e. re-enable default processing of) signal(s)
      trap - EXIT ERR
      
   else
      _err "Invalid number of args. Specify name of ONE (1) bottle to install Steam into."
      _info "Valid bottles: $BOTTLES"
   fi
}

# Quit/stop a specific Wine prefix (e.g. DXMT, DXVK, GPTk, etc.)
#
# endwine <WINEPREFIX_NAME>
# E.g. `endwine DXMT`
endwine() {
   if [[ $# -eq 0 ]]; then
      # Use killwine if WINEPREFIX isn't set
      if [[ -z "$WINEPREFIX" ]]; then
         _info "WINEPREFIX not set; killing all Wine processes instead..."
         killall -9 wineserver && killall -9 wine64-preloader && killall -9 wine
         return $?

      else
         WINEPREFIX="$WINEPREFIX" wineserver -kw
      fi

   elif [[ $# -eq 1 ]]; then
      WINEPREFIX="$BOTTLES_DIR/$1" wineserver -kw
      
   else
      _err "Invalid number of args. Specify name of ONE (1) bottle to kill."
      _info "Valid bottles: $BOTTLES"
      return 1
   fi

   _info "Successfully closed bottle!"
   return 0
}

# Run Wine with multiple arguments using Wine env set up with `set-wine`
# Execute alias `x86` (i.e. `arch -x86_64 /bin/bash`) beforehand
#
# I.e.: `x86` --> `set-wine <variant>` --> `wine <program> [args...]`
wine() {    
    # Print short message if no program or arg is given (i.e. running `wine`)
    if [[ $# -eq 0 ]]; then
        echo "Usage: wine <program> [args...]      Run the specified program" >&2
        echo "       wine --help                   Display help message and exit" >&2
        echo "       wine --version                Output version information and exit" >&2
        return 1
    fi

    # Print help message
    if [[ "$1" == "--help" ]]; then
        cat << 'EOF'
Run `arch -x86_64 /bin/bash` beforehand to ensure compatibility with x86_64 architecture
  set-wine <variant>            Set up Wine environment <gptk|dxmt|dxvk|crossover>
  wine <program> [args...]      Run Windows program in Wine environment configured with `set-wine`
  endwine [bottle]              Stop Wine server for bottle (defaults to $WINEPREFIX)

STEAM GAMING:
  dlg <bottle> <app_id>         Save Steam game via SteamCMD to specified bottle
  mvdlg <app_id> <src> <dst>    Move Steam game between bottles
  instm <bottle>                Install Windows Steam into specified bottle
  steam                         Launch Windows Steam client

DISPLAY AND PERFORMANCE:
  retina <on|off>               Set retina mode for Windows gaming via Wine
  game-mode <on|off|auto>       Set macOS game mode
  clear-cache                   Clear game shader caches

EXAMPLES:
  x86                           # Switch to x86_64 architecture
  wine --help                   # Print help message
  set-wine dxmt                 # Configure DirectX-Metal environment
  dlg DXMT 3164500              # Download game ID 3164500 into DXMT bottle
  mvdlg 2623190 DXMT GPTk       # Move game from DXMT to GPTk bottle
  wine notepad.exe              # Run Windows Notepad
  wine --version                # Print currently configured environment
  steam                         # Launch Steam client
EOF
        return 0
    fi

    # Print Wine version + info
    if [[ "$1" == "--version" ]]; then
        _wine_info
        return 0
    fi

    # Check if Wine env is configured
    _is_env_set

    # Uncomment for logging
    # local log="$LOG_DIR/log.txt"
    # echo "--- Starting Wine process at $(date) with WINEPREFIX $WINEPREFIX ---" > "$log"
    
    # Execute Windows program
    "$WINE" "$@" # >> "$log" 2>&1 # Uncomment (before `>>`) for logging

    # Uncomment for logging
    # echo "--- Exiting Wine process at $(date) ---" >> "$log"
}

############################## GAMING FUNCTIONS ##############################

# Set retina mode for Windows gaming
# Options: on, off
retina() {
    # Input validation
    if [[ $# -ne 1 ]]; then
        echo "Usage: retina <on|off>" >&2
        return 1
    fi

    # Check if Wine env is configured
    _is_env_set
    
    case "$1" in
        # Enable retina rendering for high resolution displays
        on)
            _info "Enabling retina mode..."
            wine reg add 'HKEY_CURRENT_USER\Software\Wine\Mac Driver' /v 'RetinaMode' /t REG_SZ /d 'Y' /f
            wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /v 'LogPixels' /t REG_DWORD /d "$DPI" /f
            ;;

        # Disable retina rendering and reset to standard DPI
        off)
            _info "Disabling retina mode..."
            wine reg add 'HKEY_CURRENT_USER\Software\Wine\Mac Driver' /v 'RetinaMode' /t REG_SZ /d 'N' /f
            wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /v 'LogPixels' /t REG_DWORD /d "$FORMULA_DPI" /f
            ;;

        # Invalid options
        *)
            _err "Invalid retina mode option"
            echo "Usage: retina <on|off>" >&2
            return 1
            ;;
    esac
}

# Set game mode for gaming
# Options: on, off, auto
game-mode() {
    local mode="$1"
    
    if [[ ! "$mode" =~ ^(on|off|auto)$ ]]; then
        _err "Invalid game mode option"
        echo "Usage: game-mode <on|off|auto>" >&2
        return 1
    fi

    /Applications/Xcode.app/Contents/Developer/usr/bin/gamepolicyctl game-mode set "$mode"
    _info "Game mode: $mode"
}

# Clear shader cache for Oblivion Remastered
clear-cache() {
    rm -r $(getconf DARWIN_USER_CACHE_DIR)/d3dm/OblivionRemastered-Win64-Shipping.exe/shaders.cache
    rm -r "$WINEPREFIX/$STEAMAPPS_DIR/shadercache"
    rm -r "$HOME/Documents/My Games/Oblivion Remastered"
}

# Enable anti-aliased fonts
anti-alias() {
    _info "Enabling anti-aliasing (i.e. font smoothing)..."

    wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /v 'FontSmoothing' /t REG_SZ /d '2' /f
    wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /v 'FontSmoothingOrientation' /t REG_DWORD /d 00000001 /f
    wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /v 'FontSmoothingType' /t REG_DWORD /d 00000002 /f
    wine reg add 'HKEY_CURRENT_USER\Control Panel\Desktop' /v 'FontSmoothingGamma' /t REG_DWORD /d 00000578 /f
}

# Update keyboard mappings for 'Option' and 'Command' keys
# Option  --> Alt
# Command --> CTRL
fix-kbd() {
    _info "Updating keyboard mapping..."

    wine reg add 'HKEY_CURRENT_USER\Software\Wine\Mac Driver' /v 'LeftOptionIsAlt' /t REG_SZ /d 'Y'
    wine reg add 'HKEY_CURRENT_USER\Software\Wine\Mac Driver' /v 'RightOptionIsAlt' /t REG_SZ /d 'Y'
    _info "Mapped 'Option' key to 'Alt' key"

    wine reg add 'HKEY_CURRENT_USER\Software\Wine\Mac Driver' /v 'LeftCommandIsCtrl' /t REG_SZ /d 'Y'
    wine reg add 'HKEY_CURRENT_USER\Software\Wine\Mac Driver' /v 'RightCommandIsCtrl' /t REG_SZ /d 'Y'
    _info "Mapped 'Command' key to 'CTRL' key"
}

# Launch Windows version of Steam
steam() {
    # Check if Wine env is configured
    _is_env_set

    _info "Setting up Windows version of Steam..."

    # Enable retina mode
    retina on

    # Enable font smoothing (anti-aliasing)
    anti-alias

    # Map 'Option' and 'Command' keys
    # fix-kbd

    # Enable game mode
    # game-mode on # Don't uncomment this line till game-mode func's fixed

    _info "Steam configuration complete!"

    # Start Steam
    _info "Launching Steam..."
    wine "C:\Program Files (x86)\Steam\steam.exe"
}

# Settings for FC3
fc3() {
    # Check if Wine env is configured
    _is_env_set

    # TODO: End all running Wine processes
    # endwine

    _info "Configuring optimal settings for Far Cry 3..."

    # Disable decorated window
    _info "Disabling decorated windows..."
    wine reg add 'HKEY_CURRENT_USER\Software\Wine\Mac Driver' /v 'Decorated' /t REG_SZ /d 'N' /f

    # FC3-specific env vars
    export WINEDLLOVERRIDES="dinput8,xaudio2_7=n,b;d3d11,d3d10core,dxgi=b" # winemenubuilder.exe=d
    export WINE_LARGE_ADDRESS_AWARE=1
    # export WINECPUMASK=0xff

    # Run Steam (to launch FC3)
    steam
}

############################## HELPER FUNCTIONS ##############################

# Check if Wine variant is set
_is_env_set() {
    if [[ -z "$WINE" ]]; then
        _err "No Wine environment configured." >&2
        echo "Run 'set-wine <variant>' to set up a Wine environment." >&2
        echo "Available variants: $VARIANTS" >&2
        return 1
    fi
}

# Register Steam game in libraryfolders.vdf
#
# _update_library_vdf <app_id> <size_on_disk>
# E.g. `_update_library_vdf 1623730 31616467506`
_update_library_vdf() {
    # Steam game's app ID
    local app_id="$1"

    # Size of Steam game
    local size_on_disk="$2"
            
    # Create temporary backup
    local libraryfolders_backup="$(mktemp libraryfolders.vdf.backup.XXXXXX)"
    cp libraryfolders.vdf "$libraryfolders_backup"
    _dbug "Created backup for libraryfolders.vdf at '$libraryfolders_backup'"

    # Temporary file for editing
    local libraryfolders_temp="$(mktemp libraryfolders.vdf.temp.XXXXXX)"
    _dbug "Created temporary file for editing libraryfolders.vdf at '$libraryfolders_temp'"

    # Include app ID and game size for installation record
    _dbug "Updating value for app ID '$app_id' with game size '$size_on_disk' in libraryfolders.vdf"
    awk -v app_id="$app_id" -v size_on_disk="$size_on_disk" '

    # Parse libraryfolders.vdf
    BEGIN {
        in_lib=0
        in_apps=0
        found_main_lib=0
        app_exists=0
    }
    
    # Find main section in "libraryfolder" (i.e. "0")
    /^[[:space:]]*"0"[[:space:]]*$/ {
        in_lib=1
        found_main_lib=1
        print
        next
    }
    
    # Skip all other sections
    /^[[:space:]]*"[1-9][0-9]*"[[:space:]]*$/ {
        in_lib=0
        print
        next
    }
    
    # Get "apps" key
    in_lib && found_main_lib && /^[[:space:]]*"apps"[[:space:]]*$/ {
        in_apps=1
        print
        next
    }
    
    # Open "apps"
    in_apps && /^[[:space:]]*{[[:space:]]*$/ {
        print
        next  
    }
    
    # Check if this line is an app entry that matches our target app_id
    in_apps && /^[[:space:]]*"[0-9]+"[[:space:]]+/ {
        # Extract app ID
        curr_app_id=$1
        gsub(/"/, "", curr_app_id)
        
        if (curr_app_id == app_id) {
            # Update its value
            printf "\t\t\t\"%s\"\t\t\"%s\"\n", app_id, size_on_disk
            app_exists=1
            next
        }

        print
        next
    }
    
    # Close "apps"
    in_apps && /^[[:space:]]*}[[:space:]]*$/ {
        # Only insert new entry if we never found an existing one
        if (app_exists == 0) {
            printf "\t\t\t\"%s\"\t\t\"%s\"\n", app_id, size_on_disk
        }
        print
        in_apps=0
        next
    }
    
    # Close main section in "libraryfolder"
    in_lib && found_main_lib && /^[[:space:]]*}[[:space:]]*$/ {
        in_lib=0
        found_main_lib=0
        print
        next
    }

    # Pass all other lines
    { print }

    ' "libraryfolders.vdf" > "$libraryfolders_temp"

    # Check if the operation succeeded
    if grep -q "\"$app_id\"" "$libraryfolders_temp"; then
        # Delete backup since operation was successful
        rm "$libraryfolders_backup"
        _dbug "Removed libraryfolders.vdf backup at '$libraryfolders_backup'"

        # Rename edited file to replace original copy
        mv "$libraryfolders_temp" "libraryfolders.vdf"
        _dbug "Updated libraryfolders.vdf at '$libraryfolders_temp'"

    else
        # Restore backup
        _err "Failed to update libraryfolders.vdf. Restoring backup..."
        mv "$libraryfolders_backup" "libraryfolders.vdf"
        rm "$libraryfolders_temp"
        _dbug "Backup restored!"
    fi
}

# Extract Wine version number from Wine version command (i.e. `wine --version`)
#
# `_wine_version`
# I.e. `wine-12.7.7` results in `12.7.7`
_wine_version() {
    # Check if Wine env is configured
    _is_env_set

    # Get Wine version; if unknown, exit early since there's no number to extract
    local wine_version="$($WINE --version 2>/dev/null || _err 'Unknown'; return 1)"

    # Extract version number "xxx" from string formatted "wine-xxx" (e.g. get "2", "5.3", "12.4.1" from "wine-2", "wine-5.3 ...", "... wine-12.4.1", etc.)
    # TODO: If result is empty (nothing extracted); doesn't contain "wine-", set $version_number to $wine_version
    echo "$wine_version" | sed -n 's/.*wine-\([0-9][0-9.]*\).*/\1/p'
}

# Print currently active Wine variant + environment status
_wine_info() {
    # Check if Wine env is configured
    _is_env_set

    echo "Current configuration:" >&2
    echo "       Graphics: $VARIANT_NAME ($VARIANT_ID) $VARIANT_VERSION" >&2
    echo "       Wine Version: $WINE_VERSION" >&2
    echo "       Wine Architecture: $WINEARCH" >&2
    echo "       Wine Prefix: $WINEPREFIX" >&2
    echo "       Executable: $WINE" >&2

    # TODO: Check retina mode via regedit (i.e. key set to Y or N)
    # Current method unreliable since they don't persist after shell session ends (i.e. not permanent)
}

# Prepends a blue '[INFO]' to a given string
#
# `_info <string_input>`
# E.g. `_info "File size: 4 GB"` outputs `[INFO] File size: 4 GB`
_info() {
    printf "\e[36m[INFO]\e[0m %s\n" "$1" >&2
}

# Prepends an orange '[WARNING]' to a given string
#
# `_warn <string_input>`
# E.g. `_warn "Permanently delete item? (Y/N)"` outputs `[WARNING] Permanently delete item? (Y/N)`
_warn() {
    printf "\e[33m[WARNING]\e[0m %s\n" "$1" >&2
}

# Prepends a red '[ERROR]' to a given string
#
# `_err <string_input>`
# E.g. `_err "404 Not Found"` outputs `[ERROR] 404 Not Found`
_err() {
    printf "\e[31m[ERROR]\e[0m %s\n" "$1" >&2
}

# If enabled (i.e. `ENABLE_DEBUG=1`), prepends a purple '[DEBUG]' to a given string
#
# `_dbug <string_input>`
# E.g. `_dbug "Hello World"` outputs `[DEBUG] Hello World`
_dbug() {
    [ "$ENABLE_DEBUG" -eq 1 ] && printf "\e[35m[DEBUG]\e[0m %s\n" "$1" >&2
}
