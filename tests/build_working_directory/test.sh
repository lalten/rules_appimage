#!/bin/bash
set -euxo pipefail

actual_wd="$(pwd)"

# BUILD_WORKING_DIRECTORY is not set when running the appimage directly
unset BUILD_WORKING_DIRECTORY

# BUILD_WORKING_DIRECTORY is set inside the appimage when libfuse-mounted
env="$(env -i -- PATH="/bin" tests/build_working_directory/test.appimage)"
grep -q OWD= <<<"$env"
bwd="$(grep BUILD_WORKING_DIRECTORY= <<<"$env" | cut -d= -f2-)"
[ "$bwd" = "$actual_wd" ]

# BUILD_WORKING_DIRECTORY is set inside the appimage when using APPIMAGE_EXTRACT_AND_RUN
env="$(env -i -- PATH="/bin" APPIMAGE_EXTRACT_AND_RUN=1 tests/build_working_directory/test.appimage)"
grep -q OWD= <<<"$env" && exit 1 # https://github.com/AppImage/type2-runtime/issues/23
bwd="$(grep BUILD_WORKING_DIRECTORY= <<<"$env" | cut -d= -f2-)"
[ "$bwd" = "$actual_wd" ]
