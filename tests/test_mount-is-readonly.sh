#!/bin/bash

set -eux

# The current working directory will not be the directory in which you called bazel run / bazel test, as one may expect.
# This is not specific to AppImages, but is a general Bazel thing.
# In a regular "bazel run" situation you can get the directory where Bazel was run from via BUILD_WORKING_DIRECTORY
# (see https://bazel.build/docs/user-manual#running-executables).
# If not running with Bazel, rules_appimage sets this env var to $OWD, which is the dir in which the AppImage was run.
# We can test that rules_appimage sets it because Bazel would not be set in a "bazel test" run.
[ -v BUILD_WORKING_DIRECTORY ]

# The actual current working directory is
pwd
# Which looks like
#   /tmp/appimage_extracted_3f82ce28a2cb933b1e9d659c6cbb23e8/tests/test_mount-is-readonly.runfiles/rules_appimage
# when running with APPIMAGE_EXTRACT_AND_RUN=1 / --apimage-extract-and-run, or
#   /tmp/.mount_test_mMcEHNB/tests/test_mount-is-readonly.runfiles/rules_appimage
# when mounting the SquashFS image inside the AppImage via FUSE (this is the default)

# Note that the latter is not a writable directory, so creating a file in the current directory will fail like
#   touch: cannot touch 'file': Read-only file system
touch "file" && exit 1 || true
