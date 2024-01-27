#!/usr/bin/env bash
#
# cdf.sh
# Version 0.32
# (C) 2024 by Martin Hepp, https://www.heppnetz.de
# Github repository: https://github.com/mfhepp/cdf
# Available under the MIT License


_cdf_check_path() {
   # Check if variable is not set or the value is not an existing directory
   if [ -z "${CDFPATH}" ]; then
      echo "ERROR: Favorites path not set via CDFPATH"
      return 1
   elif [ ! -d "${CDFPATH}" ]; then
      echo "ERROR: Favorites directory $CDFPATH does not exist"
      return 1  # Exit the function with a non-zero status
   else
      echo INFO: CDFPATH is set to $CDFPATH
      return 0 
   fi
}

_cdf_list() {
   # List all available shortcuts   
   echo Usage: cdf NAME
   echo
   printf "Existing directory shortcuts are:\n"
   # Note: We are looking for symbolic links, hence l
   # Old version: find $CDFPATH -maxdepth 1 -type l  -exec basename {} \; | sort | sed 's/^/ - /'
   for link in ./*; do echo " - $(basename "$link")  [$(readlink -f "$link")]"; done
   echo
}

addfav() {
   # Define addfav command, adds PWD as a symbolic link
   if [ $# -eq 0 ] || [ "$1" = "--help" ]; then
      printf "ADDFAV: Adds the current directory as a shortcut to CDFPATH\n"
      printf 'Usage: addfav NAME\n\n'
      printf 'Example:\n'
      printf '  addfav project-a: Add current directory as "project-a"\n'
      printf '  addfav --help:    Show help\n'
      printf '  addfav --list:    List all available shortcuts\n'
   elif [ "$1" = "--list" ]; then
      if ! _cdf_check_path; then
        return 1
      fi
      # List all available shortcuts
      _cdf_list
   else
      if ! _cdf_check_path; then
        return 1
      fi
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
   if [ $# -eq 0 ] || [ "$1" = "--help" ]; then
      printf "CDF: Change to a directory via a shortcut from CDFPATH\n"
      printf 'Usage: cdf NAME\n\n'
      printf 'Example:\n'
      printf '  cdf project-a: Change to the directory saved as "project-a"\n'
      printf '  cdf --help:    Show help\n'
      printf '  cdf --list:    List all available shortcuts\n\n'
      printf 'Hint: Use the TAB key for autocomplete with available shortcuts\n'

   elif [ "$1" = "--list" ]; then
      if ! _cdf_check_path; then
        return 1
      fi
      # List all available shortcuts
      _cdf_list
   else
      if ! _cdf_check_path; then
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
