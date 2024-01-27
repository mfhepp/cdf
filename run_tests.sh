#!/bin/bash
# run_tests.sh
# Runs all tests in ./tests directory

# Directory containing the scripts
script_dir="./tests"
# Save the current directory
current_dir=$(pwd)
# Define color variables
RED='\e[0;31m'
GREEN='\e[0;32m'
BLUE='\e[0;34m'
BOLD='\e[1m'
RESET='\e[0m'

# Loop over all .sh files in the directory
for script in "$script_dir"/*.sh; do
    # Check if the file is a regular file (not a directory)
    if [ -f "$script" ]; then
        printf "${BOLD}${BLUE}Running test script: $script${RESET}\n"
        # Change to the directory where the script is located
        script_dir=$(dirname "$script")
        cd "$script_dir"
        # Run the script
        bash "$(basename "$script")"
        # Capture the exit status
        status=$?
        # Return to the original directory before possibly exiting
        cd "$current_dir"
        if [ $status -ne 0 ]; then
            printf "${BOLD}${RED}ERROR: Test $script failed with status $status${RESET}\n\n"
            exit $status
        fi
    fi
done

printf "${BOLD}${GREEN}OK: All tests passed${RESET}\n\n"
