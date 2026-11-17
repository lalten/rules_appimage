#!/bin/bash

# shellcheck disable=SC1090,SC2250,SC2312

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail
set +e
f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null ||
    source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null ||
    source "$0.runfiles/$f" 2>/dev/null ||
    source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null ||
    source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null ||
    {
        echo >&2 "ERROR: cannot find $f"
        exit 1
    }
f=
set -e
# --- end runfiles.bash initialization v3 ---

# Data of this binary is found relative to the working directory, just like for the main binary.
grep -q "alt data" tests/argv0_binaries/alt_data.txt

# Only this binary depends on bazel_skylib, so resolving its apparent name requires its repo mapping.
license="$(rlocation bazel_skylib/LICENSE)"
grep -q "Apache License" "$license"

# Print which binary runs, where it runs relative to the AppDir, and its arguments.
echo "alt ${PWD#"${APPDIR}"/} ${RUNFILES_DIR#"${APPDIR}"/} $*"
