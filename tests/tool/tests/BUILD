load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("@rules_appimage_py_deps//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_test")

py_test(
    name = "test_cli",
    size = "small",
    srcs = ["test_cli.py"],
    deps = [
        requirement("pytest"),
        "//appimage/private/tool",
    ],
)

copy_file(
    name = "appimage_runtime_copy_native",
    src = select({
        "@platforms//cpu:arm64": "@appimage_runtime_aarch64//file",
        "@platforms//cpu:armv7e-m": "@appimage_runtime_armhf//file",
        "@platforms//cpu:i386": "@appimage_runtime_i686//file",
        "@platforms//cpu:x86_64": "@appimage_runtime_x86_64//file",
    }),
    out = "appimage_runtime_native",
    allow_symlink = True,
    is_executable = True,
)

copy_file(
    name = "appimage_runtime_copy_x86_64",
    src = "@appimage_runtime_x86_64//file",
    out = "appimage_runtime_x86_64",
    allow_symlink = True,
    is_executable = True,
)

py_test(
    name = "test_mkappimage",
    size = "small",
    srcs = ["test_mkappimage.py"],
    data = [
        "appimage_runtime_x86_64",
        ":appimage_runtime_native",
    ],
    deps = [
        requirement("pytest"),
        "//appimage/private/tool:mkappimage",
    ],
)
