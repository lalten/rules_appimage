load("@rules_appimage_py_deps//:requirements.bzl", "requirement")
load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@rules_python//python:defs.bzl", "py_binary", "py_test")
load("//appimage:appimage.bzl", "appimage", "appimage_test")
load(":testrules.bzl", "rules_appimage_test_rule")

sh_binary(
    name = "test_sh",
    srcs = ["test.sh"],
)

appimage_test(
    name = "appimage_test_sh",
    size = "small",
    args = ["--appimage-extract-and-run"],  # One way to run if no libfuse2 is available
    binary = ":test_sh",
)

sh_binary(
    name = "test_mount-is-readonly",
    srcs = ["test_mount-is-readonly.sh"],
)

appimage_test(
    name = "test_mount-is-readonly.appimage",
    size = "small",
    binary = ":test_mount-is-readonly",
    tags = ["requires-fakeroot"],  # This helps tests failing with `fusermount3: mount failed: Operation not permitted`
)

cc_binary(
    name = "test_cc",
    srcs = ["test.cc"],
    env = {
        "MY_APPIMAGE_ENV": "original",
        "MY_BINARY_ENV": "not lost",
    },
)

appimage_test(
    name = "appimage_test_cc",
    size = "small",
    binary = ":test_cc",
    env = {"MY_APPIMAGE_ENV": "overwritten"},  # environment variables are propagated from the binary target env attr
    tags = ["requires-fakeroot"],
)

sh_test(
    name = "appimage_test_cc_with_sh_test",
    size = "small",
    srcs = ["appimage_test_cc_with_sh_test.sh"],
    data = [":appimage_test_cc"],
)

py_binary(
    name = "test_py",
    srcs = ["test.py"],
    data = [
        "data.txt",
        "dir",  # this is a relative directory, not a target label
        ":external_bin.appimage",
        ":symlink_and_emptyfile",
    ],
    env = {"MY_BINARY_ENV": "not propagated by rules_python :("},
    main = "test.py",
)

appimage_test(
    name = "appimage_test_py",
    size = "small",
    binary = ":test_py",
    env = {"APPIMAGE_EXTRACT_AND_RUN": "1"},  # Another way to run if no libfuse2 is available
)

appimage(
    name = "appimage_py",
    binary = ":test_py",
    build_args = [
        # Example: Compress the squashfs with zstd (gzip is usually the default).
        "-comp",
        "zstd",
    ],
)

py_test(
    name = "test_appimage",
    size = "small",
    srcs = ["test_appimage.py"],
    data = [":appimage_py"],
    deps = [requirement("pytest")],
)

appimage(
    name = "external_bin.appimage",
    binary = "@rules_python//tools:wheelmaker",
    build_env = {
        # Example: Set environment variable for mksquashfs to set all file timestamps to 1970-01-01.
        "SOURCE_DATE_EPOCH": "0",
    },
)

rules_appimage_test_rule(
    name = "symlink_and_emptyfile",
    symlink = "data.txt",
)
