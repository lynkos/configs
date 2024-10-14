#!/usr/bin/env bash

[[ -r "$HOME/.profile" ]] && . "$HOME/.profile"
[[ -r "$HOME/.bashrc" ]] && . "$HOME/.bashrc"
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"

# Path to terminal theme (i.e. Pywal)
export PATH="${PATH}:$HOME/Library/Python/3.12/lib/python/site-packages"

export BASH_SILENCE_DEPRECATION_WARNING="1"
export BASH_COMPLETION_COMPAT_DIR="/opt/homebrew/etc/bash_completion.d"

# Confirm by prompting user for yes or no
ask() {
    read -p "$@ (y/n)? " answer
    case "${answer}" in
    [yY] | [yY][eE][sS])
        true
        ;;
    *)
        false
        ;;
    esac
}

# Create conda environment(s) from .yml file(s) or CLI
#
# mkenv
# mkenv [file1.yml] ... [fileN.yml]
# mkenv [env_name] [package1] ... [packageN]
# mkenv ... [file1.yml] ... [env_name] [package1] ... [packageN] ... [fileN.yml] ...
mkenv() {
   if [[ $# -eq 0 ]]; then
      conda env create

   else
      cmd=()
      for arg in "$@"; do
         case "${arg}" in
         *.[yY][mM][lL] | *.[yY][aA][mM][lL])
            if [[ ${#cmd[@]} -ne 0 ]]; then
               conda create -n "${cmd[@]}"
               unset cmd
            fi

            [[ -f "$arg" ]] && conda env create -f "$arg" ||
            echo "ERROR: $arg doesn't exist."
            ;;
         *)
            cmd+=("${arg}")
            ;;
         esac
      done

      if [[ ${#cmd[@]} -ne 0 ]]; then
         conda create -n "${cmd[@]}"
      fi
   fi
}

# Delete conda environment(s)
rmenv() {
   for env in "$@"; do
      if ask "Are you sure you want to delete $env"; then
         env_path="$(conda info --base)/envs/$env"
         [[ -e  "$env_path" ]] &&
         conda env remove -n "$env" -y &&
         rm -rf "$env_path" ||
         echo "ERROR: $env doesn't exist."
      fi
   done
}

# Rename conda environment
rnenv() {
   if [[ $# -eq 2 ]]; then
      if [[ "$CONDA_SHLVL" -eq 0 ]]; then
         act
         conda rename -n "$1" "$2"
         dac
         
      else
         conda rename -n "$1" "$2"
      fi
      
   else
      echo "ERROR: Invalid number of args. Must include:"
      echo "	* Env's current name"
      echo "	* Env's new name"
   fi
}

# Copy conda environment
cpenv() {
   if [[ $# -eq 2 ]]; then
      conda create -n "$2" --clone "$1"
      
   else
      echo "ERROR: Invalid number of args. Must include:"
      echo "	* Source env's name"
      echo "	* Env copy's name"
   fi
}

# Activate conda environment
act() {
   if [[ $# -eq 1 ]]; then
      conda activate "$1"
      
   elif [[ $# -eq 0 ]]; then
      conda activate
      
   else
      echo "ERROR: Invalid number of args. At most 1 env name is required."
   fi
}

# Export [explicit] spec file for building identical conda environments
exp() {
   if [[ $# -eq 0 ]]; then
      if ask "Export explicit specs"; then
         conda list --explicit > environment.yml
         
      else
         conda env export --from-history > environment.yml
      fi
      
   elif [[ $# -eq 1 ]]; then
      if ask "Export explicit specs"; then
         conda list --explicit > "$1"
         
      else
         conda env export --from-history > "$1"
      fi
      
   else
      echo "ERROR: Invalid number of args. At most 1 file name is required."
   fi
}

# Output [explicit] packages in conda environment
lsenv() {
   if ask "List explicit specs"; then
      conda list --explicit
      
   else
      conda list
   fi
}
