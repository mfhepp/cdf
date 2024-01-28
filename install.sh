#!/usr/bin/env bash
#
# install.sh
# Version 0.4
# (C) 2024 by Martin Hepp, https://www.heppnetz.de
# Github repository: https://github.com/mfhepp/cdf
# Available under the MIT License

printf "Installing CDF (CD from Favorites)\n"
printf "Checking dependencies.\n"
# Check if realpath is available
if ! command -v realpath >/dev/null 2>&1; then
    printf "ERROR: The required realpath command is not supported on this platform.\n"
    exit 1
fi
if ! command -v ln >/dev/null 2>&1; then
    printf "ERROR: The required ln command is not supported on this platform.\n"
    exit 1
fi 
if ! command -v find >/dev/null 2>&1; then
    printf "ERROR: The required find command is not supported on this platform.\n"
    exit 1
fi 
printf "Dependencies found.\n"
if [ -z "${CDFPATH}" ]; then
    # Default directory suffix for shortcuts (relative to $HOME)
    default_suffix="shortcuts"
    # Prompt the user for the installation directory suffix
    read -p "Enter the name of the directory for shortcuts within $HOME [$default_suffix]: " install_suffix
    # Use the default if no input is provided
    install_suffix=${install_suffix:-$default_suffix}
    # Full installation directory path
    install_dir="$HOME/$install_suffix"
    printf "Directory for shortcuts is set to: $install_dir\n"
else
    printf "Using existing CDFPATH: $CDFPATH\n"
    install_dir="$CDFPATH"
fi
mkdir -p "$install_dir"
if [ ! $? -eq 0 ]; then
    printf "ERROR: Failed to find or to create $install_dir\n"
    exit 1
fi
# Check if both ~/.bash_profile and ~/.bashrc exist
if [ -f "$HOME/.bash_profile" ] && [ -f "$HOME/.bashrc" ]; then
    printf "ERROR: Both ~/.bash_profile and ~/.bashrc exist\n"
    printf "Cannot install automatically, see README.md for manual instructions\n"
    exit 1
fi
if [ -f "$HOME/.bash_profile" ]; then
    bash_config="$HOME/.bash_profile"
elif [ -f "$HOME/.bashrc" ]; then
    bash_config="$HOME/.bashrc"
# Only ZSH but not Bash profile found:
elif [ -f "$HOME/.zshrc" ]; then
    bash_config="$HOME/.zshrc"
    printf "INFO: ZSH configuration found at $bash_config\n"
    printf "Cannot install automatically, see README.md for manual instructions\n"
    exit 1
else
    printf "ERROR: Neither ~/.bash_profile nor ~/.bashrc exists\n"
    printf "Cannot install automatically, see README.md for manual instructions\n"
    exit 1
fi
if [ -f "$HOME/.zshrc" ]; then
    printf "INFO: Additional ZSH configuration found at $HOME/.zshrc"
    printf "You can also install cdf for ZSH manually, see README.md for instructions\n"
fi
printf "Processing $bash_config\n"
counter=1
while true; do
    backup_path="${bash_config}.${counter}.bak"
    if [ ! -f "$backup_path" ]; then
        cp "$bash_config" "$backup_path"
        if [ $? -eq 0 ]; then
             printf "Backup created as $backup_path\n"
             break
        else
            printf "ERROR: Failed to create backup of ${bash_config}\n"
        exit 1
        fi
    fi
    ((counter++))
done

# Check if the cdf.sh exists
if [ ! -f "cdf.sh" ]; then
    printf "ERROR: File cdf.sh does not exist\n"
    printf "The install script must be run from the directory containing cdf.sh\n"
    exit 1
fi
# Check for previous installation
# Markers
start_marker="# >>> CDF initalize >>>"
end_marker="# <<< CDF initalize <<<"
# Check for the existence of both markers
if grep -q "$start_marker" "$bash_config" && grep -q "$end_marker" "$bash_config"; then
    printf "Previous installation found, UPDATING\n"
    # Use sed to remove the content between and including the markers
    # Detect the operating system, because sed behaves differently on OSX
    os="$(uname)"
    # Use sed to remove the content between and including the markers
    # Adjust sed command based on the operating system
    if [ "$os" = "Linux" ]; then
        # Linux sed syntax
        sed -i "/$start_marker/,/$end_marker/d" "$bash_config"
        if [ ! $? -eq 0 ]; then
            printf "ERROR: Failed to find modify $bash_config, compare with backup at $backup_path\n"
            exit 1
        fi
    elif [ "$os" = "Darwin" ]; then
        # macOS sed syntax
        sed -i '' "/$start_marker/,/$end_marker/d" "$bash_config"
        if [ ! $? -eq 0 ]; then
            printf "ERROR: Failed to find modify $bash_config, compare with backup at $backup_path\n"
            exit 1
        fi
    else
        printf "ERROR: Unsupported operating system: $os\n"
        exit 1
    fi
elif grep -q "$start_marker" "$bash_config" || grep -q "$end_marker" "$bash_config"; then
    printf "ERROR: Only one of the two markers in $bash_config found\n"
    printf "Cannot install automatically, see README.md for instructions\n"
    exit 1
else
    printf "No previous installation found, doing FRESH INSTALL\n"
fi

# Adding functions etc. to bash config file
status=0
echo "# >>> CDF initalize >>>" >> "$bash_config"; status=$((status + $?))
echo "# Setting path for shortcuts" >> "$bash_config"; status=$((status + $?))
echo "export CDFPATH=$install_dir" >> "$bash_config"; status=$((status + $?))
echo "# Added content from cdf.sh" >> "$bash_config"; status=$((status + $?))
cat cdf.sh >> "$bash_config"; status=$((status + $?))
echo "# <<< CDF initalize <<<" >> "$bash_config"; status=$((status + $?))

# Check the accumulated status
if [ $status -eq 0 ]; then
    printf "SUCCESS: Installation completed.\n"
else
    printf "ERROR: Failed to find modify $bash_config, compare with backup at $backup_path\n"
    exit 1
fi
