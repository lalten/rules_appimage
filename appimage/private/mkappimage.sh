#!/bin/bash

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail
set +e
f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
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

set -eu

mkappdir="$(rlocation rules_appimage/appimage/private/mkappdir)"
mksquashfs="$(rlocation squashfs-tools/mksquashfs)"

manifest="$1"
shift
apprun="$1"
shift
pseudofile_defs="$1"
shift
sqfs="$1"
shift
runtime="$1"
shift
appimage="$1"
shift

# Create the mksquashfs pseudo file definitions file.
# This explains to mksquashfs how to create the AppDir.
"$mkappdir" --manifest "$manifest" --apprun "$apprun" "$pseudofile_defs"

# Point mksquashfs at an empty dir so it doesn't include any other files
emptydir="$(mktemp -d)"
trap 'rm -rf "$emptydir"' EXIT

# Create the squashfs image
"$mksquashfs" "$emptydir" "$sqfs" -pf "$pseudofile_defs" "$@"

# Create the final AppImage
# by concatenating the AppImage runtime and the squashfs image of the AppDir
cat "$runtime" "$sqfs" >"$appimage"
