#!/bin/bash

# Set-up fixture
source ../cdf.sh
BACKUP_PATH=$CDFPATH
export CDFPATH="./shortcuts"

test_invalid_arguments() {
    if _validate_basename "~/foo"; then
    echo "ERROR: Invalid argument ~/foo not detected"
    return 1
    fi

    if _validate_basename "/foo"; then
    echo "ERROR: Invalid argument /foo not detected"
    return 1
    fi

    if _validate_basename ".foo"; then
    echo "ERROR: Invalid argument .foo not detected"
    return 1
    fi

    if _validate_basename "foo.bar"; then
    echo "ERROR: Invalid argument foo.bar not detected"
    return 1
    fi

    if _validate_basename "foo/"; then
    echo "ERROR: Invalid argument foo/ not detected"
    return 1
    fi

    if _validate_basename "foo/bar"; then
    echo "ERROR: Invalid argument foo/ not detected"
    return 1
    fi

    if ! _validate_basename ""; then
    echo "ERROR: Invalid empty argument not detected"
    return 1
    fi

    if _validate_basename "  "; then
    echo "ERROR: Invalid argument just whitespace not detected"
    return 1
    fi        

    if ! _validate_basename "foo"; then
    echo "ERROR: Valid argument foo rejected"
    return 1
    fi   
}

test_invalid_arguments
status=$?
# Clean-up
export CDFPATH=$BACKUP_PATH

if [ $status -ne 0 ]; then
    echo "ERROR: At least one test failed, aborting"
    exit $status
else
    echo "OK: All tests from $0 passed"
fi

