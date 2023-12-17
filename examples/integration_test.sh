#!/bin/bash

set -euxo pipefail

bazel build //:hello.appimage

trap "rm -f hello.appimage" EXIT
cp -f bazel-bin/hello.appimage .

ls -lah hello.appimage
file hello.appimage

if ! output="$(./hello.appimage 2>&1)"; then
    echo "Unexpected failure: $output"
    exit 1
elif [[ $output != "Hello, World!" ]]; then
    echo "Unexpected output: $output"
    exit 1
fi
