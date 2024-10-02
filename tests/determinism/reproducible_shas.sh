#!/bin/bash

# When an appimage is rebuilt, the sha256sum of the resulting file must be the same.
# In other words, the build must be deterministic.
# We check this by building the same targets twice and comparing the sha256sums.

set -euxo pipefail

query='kind("appimage rule", //...)'
tempdir="$(mktemp -d)"
targets="$tempdir/targets"
files="$tempdir/files"
trap 'rm -rf "$tempdir"' EXIT

bazel query "$query" >"$targets"
bazel cquery "$query" --output files >"$files"

bazel build --target_pattern_file="$targets"
xargs --arg-file="$files" sha256sum | tee "$tempdir/shas0.txt"

xargs --arg-file="$files" rm -f

bazel build --remote_cache= --disk_cache= --target_pattern_file="$targets"
xargs --arg-file="$files" sha256sum | tee "$tempdir/shas1.txt"

diff -u "$tempdir/shas0.txt" "$tempdir/shas1.txt"
