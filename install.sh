#!/usr/bin/env bash
#
# install.sh
# Version 0.1
# (C) 2024 by Martin Hepp, https://www.heppnetz.de
# Github repository: https://github.com/mfhepp/cdf
# Available under the MIT License

echo "Installing CDF (CD from Favorites)"
# Default directory suffix for shortcuts (relative to $HOME)
default_suffix="shortcuts"
# Prompt the user for the installation directory suffix
read -p "Enter the name of the directory for shortcuts within $HOME [$default_suffix]: " install_suffix
# Use the default if no input is provided
install_suffix=${install_suffix:-$default_suffix}
# Full installation directory path
install_dir="$HOME/$install_suffix"
echo "Directory for shortcuts is set to: $install_dir"
mkdir -p $install_dir
# Check if both ~/.bash_profile and ~/.bashrc exist
if [ -f "$HOME/.bash_profile" ] && [ -f "$HOME/.bashrc" ]; then
    echo "ERROR: Both ~/.bash_profile and ~/.bashrc exist"
    echo "Cannot install automatically, see README.md for instructions"
    exit 1
fi
if [ -f "$HOME/.bash_profile" ]; then
    bash_config="$HOME/.bash_profile"
elif [ -f "$HOME/.bashrc" ]; then
    bash_config="$HOME/.bashrc"
else
    echo "ERROR: Neither ~/.bash_profile nor ~/.bashrc exists"
    echo "Cannot install automatically, see README.md for instructions"
    exit 1
fi
echo Processing $bash_config
counter=1
while true; do
    backup_path="${bash_config}.${counter}.bak"
    if [ ! -f "$backup_path" ]; then
        cp "$bash_config" "$backup_path"
        echo "Backup created as $backup_path"
        break
    fi
    ((counter++))
done
# Check if the cdf.sh exists
if [ ! -f "cdf.sh" ]; then
    echo "ERROR: File cdf.sh does not exist"
    echo "The install script must be run from the directory containing cdf.sh"
    exit 1
fi
# Check for previous installation
# Markers
start_marker="# >>> CDF initalize >>>"
end_marker="# <<< CDF initalize <<<"
# Check for the existence of both markers
if grep -q "$start_marker" "$bash_config" && grep -q "$end_marker" "$bash_config"; then
    echo "Previous installation found, UPDATING"
    # Use sed to remove the content between and including the markers
    # Detect the operating system, because sed behaves differently on OSX
    os="$(uname)"
    # Use sed to remove the content between and including the markers
    # Adjust sed command based on the operating system
    if [ "$os" = "Linux" ]; then
        # Linux sed syntax
        sed -i "/$start_marker/,/$end_marker/d" "$bash_config"
    elif [ "$os" = "Darwin" ]; then
        # macOS sed syntax
        sed -i '' "/$start_marker/,/$end_marker/d" "$bash_config"
    else
        echo "ERROR: Unsupported operating system: $os"
        exit 1
    fi
elif grep -q "$start_marker" "$bash_config" || grep -q "$end_marker" "$bash_config"; then
    echo "ERROR: Only one of the two markers in $bash_config found"
    echo "Cannot install automatically, see README.md for instructions"
    exit 1
else
    echo "No previous installation found, doing FRESH INSTALL"
fi

# Adding functions etc. to bash config file
echo >> "$bash_config"
echo "# >>> CDF initalize >>>" >> "$bash_config"
echo "# Setting path for shortcuts" >> "$bash_config"
echo "export CDFPATH=$install_dir" >> "$bash_config"
echo "# Added content from cdf.sh" >> "$bash_config"
cat cdf.sh >> "$bash_config"
echo "# <<< CDF initalize <<<" >> "$bash_config"
echo SUCCESS: Installation completed.