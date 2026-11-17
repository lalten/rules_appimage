#!/bin/bash

set -euxo pipefail

appimage="$PWD/tests/argv0_binaries/test.appimage"
bindir="$TEST_TMPDIR/bin"
mkdir -p "$bindir"
for name in alt "it's alt" unknown; do
    ln -s "$appimage" "$bindir/$name"
done

run() {
    env -i -- PATH="$bindir:/bin:/usr/bin" "$@"
}

for mode in fuse extract-and-run; do
    if [[ $mode == extract-and-run ]]; then
        export APPIMAGE_EXTRACT_AND_RUN=1
    fi

    # The main binary runs when invoked under any name other than the argv0_binaries keys
    main="$(run "$appimage" a b)"
    [[ $main == "main tests/argv0_binaries/main.runfiles/"*" tests/argv0_binaries/main.runfiles a b" ]]
    [[ "$(run "$bindir/unknown" a b)" == "$main" ]]

    # The alternative binary runs in the same working directory and runfiles tree as the main binary
    expected="alt${main#main}"
    [[ "$(run "$bindir/alt" a b)" == "$expected" ]]
    [[ "$(run "$bindir/it's alt" a b)" == "$expected" ]]
    [[ "$(cd "$bindir" && run ./alt a b)" == "$expected" ]]
    [[ "$(run alt a b)" == "$expected" ]]
done
unset APPIMAGE_EXTRACT_AND_RUN

# Without the AppImage runtime there is no $ARGV0 (nor $APPDIR) and the main binary runs
cd "$TEST_TMPDIR"
"$appimage" --appimage-extract >/dev/null
[[ "$(run APPDIR="$PWD/squashfs-root" squashfs-root/AppRun a b)" == "$main" ]]
