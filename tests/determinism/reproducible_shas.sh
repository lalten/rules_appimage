#!/bin/bash

# When an appimage is rebuilt, the sha256sum of the resulting file must be the same.
# In other words, the build must be deterministic.
# We check this by building the same targets twice and comparing the sha256sums.

set -euxo pipefail

query='kind("appimage rule", //...)'
tempdir="${1:-/tmp/determinism-test}"
rm -rf "$tempdir"
mkdir -p "$tempdir"
targets="$tempdir/targets"
files="$tempdir/files"

bazel query "$query" >"$targets"
bazel cquery "$query" --output files >"$files"

bazel clean
bazel build --remote_cache= --disk_cache= --target_pattern_file="$targets" --platforms=//:linux_x86_64
xargs --arg-file="$files" sha256sum | tee "$tempdir/shas0.txt"

mkdir -p "$tempdir/build0"
xargs --arg-file="$files" -I{} mv {} "$tempdir/build0/"

bazel clean
bazel build --remote_cache= --disk_cache= --target_pattern_file="$targets" --platforms=//:linux_x86_64
xargs --arg-file="$files" sha256sum | tee "$tempdir/shas1.txt"

mkdir -p "$tempdir/build1"
xargs --arg-file="$files" -I{} cp {} "$tempdir/build1/"

diff -u "$tempdir/shas0.txt" "$tempdir/shas1.txt"
