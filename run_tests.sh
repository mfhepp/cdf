#!/bin/bash
# run_tests.sh
# Runs all tests in ./tests directory

# Directory containing the scripts
script_dir="./tests"
# Save the current directory
current_dir=$(pwd)

# Loop over all .sh files in the directory
for script in "$script_dir"/*.sh; do
    # Check if the file is a regular file (not a directory)
    if [ -f "$script" ]; then
        echo "Running test script: $script"
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
            echo "ERROR: Test $script failed with status $status"
            exit $status
        fi
    fi
done

echo "OK: All tests passed"
