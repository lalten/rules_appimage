load("//appimage:appimage.bzl", "appimage", "appimage_test")
load("@rules_python//python:defs.bzl", "py_binary", "py_test")
load("@py_deps//:requirements.bzl", "requirement")
load(":testrules.bzl", "rules_appimage_test_rule")

sh_binary(
    name = "test_sh",
    srcs = ["test.sh"],
)

appimage_test(
    name = "appimage_test_sh",
    args = ["--appimage-extract-and-run"],  # One way to run if no libfuse2 is available
    binary = ":test_sh",
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
    main = "test.py",
)

appimage_test(
    name = "appimage_test_py",
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
