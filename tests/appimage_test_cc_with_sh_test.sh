#!/bin/bash

set -eux

exec env --ignore-environment \
    USE_BAZEL_VERSION="${USE_BAZEL_VERSION:-latest}" \
    "tests/appimage_test_cc" --appimage-extract-and-run
