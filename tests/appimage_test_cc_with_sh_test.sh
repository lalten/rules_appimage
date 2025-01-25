#!/bin/bash

set -eux

exec env --ignore-environment "tests/appimage_test_cc" --appimage-extract-and-run
