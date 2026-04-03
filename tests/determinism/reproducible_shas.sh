#!/bin/bash

# When an appimage is rebuilt, the sha256sum of the resulting file must be the same.
# In other words, the build must be deterministic.
# We check this by building the same targets twice and comparing the sha256sums.

set -euxo pipefail

query='kind("appimage rule", //...)'
tempdir="${RUNNER_TEMP:-/tmp}/determinism-test"
rm -rf "$tempdir"
mkdir -p "$tempdir"
targets="$tempdir/targets"
files="$tempdir/files"

bazel query "$query" >"$targets"
bazel cquery "$query" --platforms=//:linux_x86_64 --output files >"$files"

archive_outputs() {
    local srcs="$1"
    local dest="$2"
    while IFS= read -r file; do
        target="$dest/$file"
        mkdir -p "$(dirname "$target")"
        cp "$file" "$target"
    done <"$srcs"
}

bazel clean
bazel build --remote_cache= --disk_cache= --target_pattern_file="$targets" --platforms=//:linux_x86_64
xargs --arg-file="$files" sha256sum | tee "$tempdir/shas0.txt"
archive_outputs "$files" "$tempdir/build0"

bazel clean
bazel build --remote_cache= --disk_cache= --target_pattern_file="$targets" --platforms=//:linux_x86_64
xargs --arg-file="$files" sha256sum | tee "$tempdir/shas1.txt"
archive_outputs "$files" "$tempdir/build1"

diff -u "$tempdir/shas0.txt" "$tempdir/shas1.txt"
