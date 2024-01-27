#!/usr/bin/env bash
#
# cdf.sh
# Version 0.2
# (C) 2024 by Martin Hepp, https://www.heppnetz.de
# Github repository: https://github.com/mfhepp/cdf
# Available under the MIT License


_cdf_check_environment() {
   # Check if CDFPATH is set
   if [ -z "${CDFPATH}" ]; then
      echo "ERROR: Favorites path not set via CDFPATH"
      return 1
   # Check if value is an existing directory
   elif [ ! -d "${CDFPATH}" ]; then
      echo "ERROR: Favorites directory $CDFPATH does not exist"
      return 1  # Exit the function with a non-zero status
   else
      echo INFO: CDFPATH is set to $CDFPATH
   fi
   # Check if realpath is available
   if ! command -v realpath >/dev/null 2>&1; then
      echo "ERROR: The required realpath command is not supported on this platform."
      return 1
   fi
   if ! command -v ln >/dev/null 2>&1; then
      echo "ERROR: The required ln command is not supported on this platform."
      return 1
   fi   
}

# Function to check if name for shortcut is a safe name for the symbolic link
_validate_basename() {
    local input=$1
    if [ -z "$input" ]; then
       # echo "ERROR: Argument is empty."
       return 1
    fi
    local sanitized
    # Remove leading and trailing whitespace and replace forbidden characters
    sanitized=$(echo "$input" | xargs | sed 's/[^a-zA-Z0-9_-]/_/g')
    if [[ "$sanitized" != "$input" ]]; then
        # echo "ERROR: Argument contains invalid characters (consider $sanitized instead)"
        return 1
    fi
}

_cdf_list() {
   # List all available shortcuts   
   echo Usage: cdf NAME
   echo
   printf "Existing directory shortcuts are:\n"
   # Note: We are looking for symbolic links, hence l
   # Old version: find $CDFPATH -maxdepth 1 -type l  -exec basename {} \; | sort | sed 's/^/ - /'
   # for link in ./*; do echo " - $(basename "$link")  [$(readlink -f "$link")]"; done
   find "$CDFPATH" -maxdepth 1 -type l -print0 | while IFS= read -r -d '' symlink; do
      echo " - $(basename "$symlink")  [$(realpath "$symlink")]"
   done   
   echo
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
      if [[ "$CURRENT_DIR" = "$CDFPATH" || "$CURRENT_DIR" == "$CDFPATH"/* ]]; then
        echo "ERROR: You cannot create shortcuts to the shortcuts folder or its subdirectories"
        return 1
      # Check if we are INSIDE a symbolic link
      elif [ "$CURRENT_DIR" != $(realpath $CURRENT_DIR) ]; then
        echo "ERROR: You cannot create shortcuts to symbolic links"
        echo "Hint: $CURRENT_DIR expands to $(realpath $CURRENT_DIR)"
        return 1
      fi
      # Check if argument is a valid basename
      if ! _validate_basename "$1"; then
         echo "ERROR: Invalid name for shortcut"
         return 1
      fi
      filepath="$CDFPATH/$1"
      if [ -e "$filepath" ]; then
         echo "ERROR: Shortcut $1 is already in use (or another file or directory $filepath exists)"
         return 1
      else
         echo "Creating shortcut $1 for $PWD"
         ln -s $PWD $filepath
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
         echo "ERROR: Invalid name for shortcut"
         return 1
      fi
      filepath="$CDFPATH"/"$1"
      if [ -L "$filepath" ]; then
         echo "Following the symbolic link: $filepath"
         cd $filepath 
         echo You are now here:
         cd $(realpath .)
         echo "    $(pwd)"
      else
         echo "ERROR: Shortcut $1 does not exist as a symbolic link in $CDFPATH"
      fi
   fi
}
# Define autocomplete helper
# Credits to ChatGPT 4
_cdf_autocomplete() {
    local cur=${COMP_WORDS[COMP_CWORD]}
    local IFS=$'\n'  # Change the Internal Field Separator to handle spaces and special characters in file names
    # Use find to list symbolic links in $CDPATH
    COMPREPLY=($(compgen -W "$(find $CDFPATH -maxdepth 1 -type l -exec basename {} \;)" -- "$cur"))
}
complete -F _cdf_autocomplete cdf
