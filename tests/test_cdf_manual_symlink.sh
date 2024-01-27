#!/bin/bash

# Test function
test_cdf() {
    # Test if cdf foo works
    cd ../bar
    cdf foo > /dev/null 2>&1
    local status=$?
    if [ ! "$status" -eq 0 ]; then
        echo "ERROR: Command cdf foo not exit with status 0 (actual status: $status)."
        return 1
    fi
    if [ "$PWD" = "$real_path" ]; then
        echo "Test Passed: Current directory is $real_path"
    else
        echo "ERROR: cdf foo failed, current directory is $PWD, should be $real_path"
        return 1
    fi
}

# Set-up fixture
source ../cdf.sh
BACKUP_PATH=$CDFPATH
export CDFPATH="../../shortcuts"
symlink_path="${CDFPATH%/}/foo"
# All paths are relative to this directory
cd ./fixtures/testfolders/foo
# Check that symlink does not yet exist
if [ -L "$symlink_path" ]; then
    echo "ERROR: Symlink at $symlink_path already exists"
    exit 1
else
    echo "Test Passed: No previous symlink $symlink_path"
fi
# Create symlink manually
ln -s "$PWD" "$symlink_path"
# Test if symlink has been be created
if [ ! -L "$symlink_path" ]; then
    echo "ERROR: Symlink at $symlink_path has not been created"
    exit 1
fi
# Test if symlink points to the proper path
real_path=$(realpath "$symlink_path")
if [ "$real_path" = "$PWD" ]; then
    echo "Test Passed: $symlink_path points to $PWD"
else
    echo "ERROR: Symlink at $symlink_path does not point to $PWD"
    echo "  DEBUG: $real_path"
    return 1
fi

# Run test(s)
test_cdf
status=$?
# Clean-up
# Delete symlink in a secure way (rm with symlinks can be a beast!)
# Check if the variable is not empty and points to a file that is a symbolic link
if [[ -n "$symlink_path" && -L "$symlink_path" ]]; then
    # echo "INFO: Removing temporary symbolic link: $symlink_path"
    rm "$symlink_path"
else
    echo "ERROR: \$symlink_path is either empty or $symlink_path is not a symbolic link"
    echo "Cannot remove temporary symbolic link"
fi
if [ $status -ne 0 ]; then
    echo "ERROR: At least one test failed, aborting"
    export CDFPATH=$BACKUP_PATH
    exit $status
else
    echo "OK: All tests from $0 passed"
fi


