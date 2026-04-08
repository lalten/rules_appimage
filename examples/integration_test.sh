#!/bin/bash

set -euxo pipefail

cd "$(dirname "$0")"

bazel build //:hello.appimage

trap "rm -f hello.appimage; rm -rf squashfs-root" EXIT
cp -f bazel-bin/hello.appimage .

ls -lah hello.appimage

[[ "$(file hello.appimage)" == "hello.appimage: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, stripped" ]] || exit 1

check_output() {
    local cmd="$1"
    local output
    if ! output="$("$cmd" 2>&1)"; then
        echo "Unexpected failure from $cmd: $output"
        exit 1
    elif [[ $output != "Hello, World!" ]]; then
        echo "Unexpected output from $cmd: $output"
        exit 1
    fi
}

# Check that the AppImage can be executed and produces the expected output
check_output ./hello.appimage

# Check that calling the AppRun script inside the AppImage with a relative and absolute path produces the expected output
./hello.appimage --appimage-extract
check_output ./squashfs-root/AppRun
check_output "$(realpath ./squashfs-root/AppRun)"
