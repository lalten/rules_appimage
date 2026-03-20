#!/bin/sh
# Test that root_symlinks are correctly placed in the AppImage runfiles.
set -eux

find . -type f
test -L "${RUNFILES_DIR}/root_symlink_to_data"
test -f "${RUNFILES_DIR}/root_symlink_to_data"
grep -q data "${RUNFILES_DIR}/root_symlink_to_data"
