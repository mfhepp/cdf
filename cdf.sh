#!/usr/bin/env bash
#
# cdf.sh
# Version 0.3.1
# (C) 2024 by Martin Hepp, https://www.heppnetz.de
# Github repository: https://github.com/mfhepp/cdf
# Available under the MIT License


_cdf_check_environment() {
   # Check if CDFPATH is set
   if [ -z "${CDFPATH}" ]; then
      printf "ERROR: Favorites path not set via CDFPATH\n"
      return 1
   # Check if value is an existing directory
   elif [ ! -d "${CDFPATH}" ]; then
      printf "ERROR: Favorites directory $CDFPATH does not exist\n"
      return 1  # Exit the function with a non-zero status
   else
      printf "INFO: CDFPATH is set to $CDFPATH\n"
   fi
   # Check if realpath is available
   if ! command -v realpath >/dev/null 2>&1; then
      printf "ERROR: The required realpath command is not supported on this platform\n"
      return 1
   fi
   if ! command -v ln >/dev/null 2>&1; then
      printf "ERROR: The required ln command is not supported on this platform\n"
      return 1
   fi
   if ! command -v find >/dev/null 2>&1; then
      printf "ERROR: The required find command is not supported on this platform.\n"
      return 1
   fi       
}

# Function to check if name for shortcut is a safe name for the symbolic link
_validate_basename() {
    local input="$1"
    if [ -z "$input" ]; then
       # echo "ERROR: Argument is empty."
       return 1
    fi
    local sanitized
    # Remove leading and trailing whitespace and replace forbidden characters
    sanitized=$(echo "$input" | xargs | sed 's/[^a-zA-Z0-9_-]/_/g')
    if [ "$sanitized" != "$input" ]; then
        # echo "ERROR: Argument contains invalid characters (consider $sanitized instead)"
        return 1
    fi
}


_cdf_list() {
   # List all available shortcuts   
   printf "Usage: cdf NAME\n\n"
   printf "Existing directory shortcuts are:\n"
   # Note: We are looking for symbolic links, hence l
   # Old version: find $CDFPATH -maxdepth 1 -type l  -exec basename {} \; | sort | sed 's/^/ - /'
   # for link in ./*; do echo " - $(basename "$link")  [$(readlink -f "$link")]"; done
   find "$CDFPATH" -maxdepth 1 -type l -print0 | while IFS= read -r -d '' symlink; do
      printf " - $(basename "$symlink")  [$(realpath "$symlink")]\n"
   done   
   printf "\n"
}

addfav() {
   # Define addfav command, adds PWD as a symbolic link
   if ! _cdf_check_environment; then
     return 1
   fi
   if [ $# -eq 0 ] || [ "$1" = "--help" ]; then
      printf "ADDFAV: Adds the current directory as a shortcut to CDFPATH\n"
      printf 'Usage: addfav NAME\n\n'
      printf 'Example:\n'
      printf '  addfav project-a: Add current directory as "project-a"\n'
      printf '  addfav --help:    Show help\n'
      printf '  addfav --list:    List all available shortcuts\n'
   elif [ "$1" = "--list" ]; then
      # List all available shortcuts
      _cdf_list
   else
      # Check that the current directory is neither the place for the symlinks nor a subdirectory therof
      CURRENT_DIR=$(pwd)
      # Bash-only version: if [[ "$CURRENT_DIR" = "$CDFPATH" || "$CURRENT_DIR" == "$CDFPATH"/* ]]; then
      if [ "$CURRENT_DIR" = "$CDFPATH" ] || [ "${CURRENT_DIR##$CDFPATH/}" != "$CURRENT_DIR" ]; then
        printf "ERROR: You cannot create shortcuts to the shortcuts folder or its subdirectories\n"
        return 1
      # Check if we are INSIDE a symbolic link
      elif [ "$CURRENT_DIR" != $(realpath $CURRENT_DIR) ]; then
        printf "ERROR: You cannot create shortcuts to symbolic links\n"
        printf "Hint: $CURRENT_DIR expands to $(realpath "$CURRENT_DIR")\n"
        return 1
      fi
      # Check if argument is a valid basename
      if ! _validate_basename "$1"; then
         printf "ERROR: Invalid name for shortcut\n"
         return 1
      fi
      filepath="$CDFPATH/$1"
      if [ -e "$filepath" ]; then
         printf "ERROR: Shortcut $1 is already in use (or another file or directory $filepath exists)\n"
         return 1
      else         
         ln -s "$PWD" "$filepath"
         if [ $? -eq 0 ]; then
            printf "OK: Shortcut $1 for $PWD added\n"
         else
            printf "ERROR: Failed to create shortcut $1 for $PWD\n"
            return 1
         fi
      fi 
   fi
}

cdf() {
   # Define cdf command ("change to favorite")
   if ! _cdf_check_environment; then
      return 1
   fi
   if [ $# -eq 0 ] || [ "$1" = "--help" ]; then
      printf "CDF: Change to a directory via a shortcut from CDFPATH\n"
      printf 'Usage: cdf NAME\n\n'
      printf 'Example:\n'
      printf '  cdf project-a: Change to the directory saved as "project-a"\n'
      printf '  cdf --help:    Show help\n'
      printf '  cdf --list:    List all available shortcuts\n\n'
      printf 'Hint: Use the TAB key for autocomplete with available shortcuts\n'
   elif [ "$1" = "--list" ]; then
      # List all available shortcuts
      _cdf_list
   else
      # Check if argument is a valid basename
      if ! _validate_basename "$1"; then
         printf "ERROR: Invalid name for shortcut\n"
         return 1
      fi
      filepath="$CDFPATH"/"$1"
      if [ -L "$filepath" ]; then
         printf "Following the symbolic link: $filepath\n"
         real_path=$(realpath "$filepath")
         cd "$real_path"
         if [ $? -eq 0 ]; then
            printf "You are now here: $(pwd)\n"
         else
            printf "ERROR: Failed to change directory to $real_path\n"
            return 1
         fi
      else
         printf "ERROR: Shortcut $1 does not exist as a symbolic link in $CDFPATH\n"
         return 1
      fi
   fi
}

# Define autocomplete helper (currently limited to Bash)
# Credits to ChatGPT 4
_cdf_autocomplete() {
    local cur files
    if [ -n "$BASH_VERSION" ]; then
        # Bash environment
        cur=${COMP_WORDS[COMP_CWORD]}
    elif [ -n "$ZSH_VERSION" ]; then
        # Zsh environment
        cur=${words[CURRENT]}
    fi
    # Use a wildcard pattern to get symbolic links
    local IFS=$'\n'
    files=()
    for file in "$CDFPATH"/*; do
        [ -L "$file" ] && files+=("$(basename "$file")")
    done
    if [ -n "$BASH_VERSION" ]; then
        # Bash completion
        COMPREPLY=($(compgen -W "${files[*]}" -- "$cur"))
    elif [ -n "$ZSH_VERSION" ]; then
        # Zsh completion
        compadd -- "${files[@]}"
    fi
}

# Set up completion for the shell
# For the moment, we keep this in cdf.sh
# This adds a bit of overhead but simplifies the installation

if [ -n "$BASH_VERSION" ]; then
    complete -F _cdf_autocomplete cdf
elif [ -n "$ZSH_VERSION" ]; then
    autoload -U +X compinit && compinit
    autoload -U +X bashcompinit && bashcompinit
    compdef _cdf_autocomplete cdf
fi

