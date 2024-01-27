#!/bin/bash

# Test function
test_path_not_set() {
    command="$1" 
    # Run the script or command
    "$command" > /dev/null 2>&1
    # Capture the exit status
    local status=$?
    # Check if the exit status is 1
    if [ $status -eq 1 ]; then
        echo "Test Passed: $command exited with status 1 when CDFPATH is not set."
    else
        echo "Test FAILED: $command did not exit with status 1 (actual status: $status) when CDFPATH is not set."
        return 1
    fi
}

test_path_set_valid() {
    command="$1"
    # Run the script or command
    "$command" > /dev/null 2>&1
    # Capture the exit status
    local status=$?
    # Check if the exit status is 0
    if [ $status -eq 0 ]; then
        echo "Test Passed: $command exited with status 0 when CDFPATH is set and directory exists."
    else
        echo "Test FAILED: $command exited with status $status even if CDFPATH is set and directory exists."
        echo "  DEBUG: CDFPATH=$CDFPATH"
        echo "  DEBUG: PWD=$PWD"
        return 1
    fi
}

test_path_set_invalid() {
    # Run the script without arguments
    command="$1"
    "$command" > /dev/null 2>&1
    # Capture the exit status
    local status=$?
    # Check if the exit status is 1
    if [ $status -eq 1 ]; then
        echo "Test Passed: $command exited with status 1 when CDFPATH is set but directory does not exist."
    else
        echo "Test FAILED: $command exited with status $status when CDFPATH is set but directory does not exist."
        echo "  DEBUG: CDFPATH=$CDFPATH"
        echo "  DEBUG: PWD=$PWD"
        return 1
    fi
}

# Test runner for catching the first breaking test
run_test() {
    test_command="$@"
    $test_command
    status=$?
    if [ $status -ne 0 ]; then
        echo "ERROR: At least one test failed, aborting"
        # Clean-up
        export CDFPATH=$BACKUP_PATH
        exit $status
    fi
}

# Run the test
# Set-up fixture
source ../cdf.sh
BACKUP_PATH=$CDFPATH
# Tests if missing CDFPATH exits with an error
unset CDFPATH
run_test test_path_not_set "cdf"
run_test test_path_not_set "addfav"
# Tests if set CDFPATH to existing directory exits with no error
export CDFPATH="./fixtures/shortcuts"
run_test test_path_set_valid "cdf"
run_test test_path_set_valid "addfav"
# Tests if set CDFPATH to non-existing directory exits with an error
export CDFPATH="./fixtures/shortcuts123"
run_test test_path_set_invalid "cdf"
run_test test_path_set_invalid "addfav"
export CDFPATH=$BACKUP_PATH
echo "OK: All tests from $0 passed"