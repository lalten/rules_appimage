#!/bin/bash

set -euxo pipefail

cd "$(dirname "$0")"

bazel build //:hello.appimage

trap "rm -f hello.appimage" EXIT
cp -f bazel-bin/hello.appimage .

ls -lah hello.appimage

[[ "$(file hello.appimage)" == "hello.appimage: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, stripped" ]] || exit 1

if ! output="$(./hello.appimage 2>&1)"; then
    echo "Unexpected failure: $output"
    exit 1
elif [[ $output != "Hello, World!" ]]; then
    echo "Unexpected output: $output"
    exit 1
fi
