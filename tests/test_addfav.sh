#!/bin/bash
# TODO: Refactor to functions so that cleanup will work also if test fails


# Set-up fixture
source ../cdf.sh
BACKUP_PATH=$CDFPATH
export CDFPATH="../../shortcuts"
symlink_path="${CDFPATH%/}/bar"

# All paths are relative to this directory
cd ./fixtures/testfolders/bar

# Check that symlink does not yet exist
if [ -L "$symlink_path" ]; then
    echo "ERROR: Symlink at $symlink_path already exists."
    exit 1
else
    echo "Test Passed: No previous symlink $symlink_path."
fi

# ###############################
# Test if symlink can be created
# ###############################
addfav bar > /dev/null 2>&1
status=$?
if [ ! "$status" -eq 0 ]; then
    echo "ERROR: Command did not exit with status 0 (actual status: $status)."
    exit 1
fi
if [ ! -L "$symlink_path" ]; then
    echo "ERROR: Symlink at $symlink_path has not been created."
    exit 1
fi

# Test if symlink points to the proper path
real_path=$(realpath "$symlink_path")
if [ "$real_path" = "$PWD" ]; then
    echo "Test Passed: $symlink_path points to $PWD"
else
    echo "ERROR: Symlink at $symlink_path does not point to $PWD."
    echo "  DEBUG: $real_path"
    exit 1
fi

# Clean up
# Delete symlink in a secure way (rm with symlinks can be a beast!)
# Check if the variable is not empty and points to a file that is a symbolic link
if [[ -n "$symlink_path" && -L "$symlink_path" ]]; then
    # echo "INFO: Removing temporary symbolic link: $symlink_path"
    rm "$symlink_path"
else
    echo "ERROR: \$symlink_path is either empty or $symlink_path is not a symbolic link."
    echo "Cannot remove temporary symbolic link."
fi
export CDFPATH=$BACKUP_PATH

echo "OK: All tests from $0 passed"
