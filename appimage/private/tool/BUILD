load("@rules_python//python:defs.bzl", "py_binary")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

copy_file(
    name = "appimage_runtime_copy",
    src = select({
        "@platforms//cpu:x86_64": "@appimage_runtime_x86_64//file",
        "@platforms//cpu:arm64": "@appimage_runtime_aarch64//file",
        "@platforms//cpu:armv7e-m": "@appimage_runtime_armhf//file",
        "@platforms//cpu:i386": "@appimage_runtime_i686//file",
    }),
    out = "appimage_runtime",
    allow_symlink = True,
    is_executable = True,
)

copy_file(
    name = "mksquashfs_copy",
    src = select({
        "@platforms//cpu:x86_64": "@mksquashfs_x86_64//file",
        "@platforms//cpu:arm64": "@mksquashfs_aarch64//file",
        "@platforms//cpu:armv7e-m": "@mksquashfs_armhf//file",
        "@platforms//cpu:i386": "@mksquashfs_i686//file",
    }),
    out = "mksquashfs",
    allow_symlink = True,
    is_executable = True,
)

py_library(
    name = "mkappimage",
    srcs = ["mkappimage.py"],
    data = [
        ":appimage_runtime",
        ":mksquashfs",
    ],
    visibility = ["//visibility:public"],
    deps = ["@rules_python//python/runfiles"],
)

py_binary(
    name = "tool",
    srcs = ["cli.py"],
    main = "cli.py",
    python_version = "PY3",
    visibility = ["//visibility:public"],
    deps = [":mkappimage"],
)
