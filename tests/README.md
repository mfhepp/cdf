# This folder containts a simple test suite

## Running tests

```bash
./run_tests.sh
```
This runs all tests found in `./tests/*`.

## Implemented

- Check if `cdf` and `addfav` fail if `CDFPATH` is not set or is not a directory, and that they pass if both is fine.
- Test if a directory can be added and results in a proper symlink in the proper place.
- Test if a manually created shortcut/symlink works with `cdf NAME`.

## Ideas for future tests

- Test if creating a shortcut for a path that is itself a symlink fails.
- Test if creating a shortcut for a path that is not identical with its realpath fails.
- Test if `cdf --list` returns the proper list of shortcuts.
