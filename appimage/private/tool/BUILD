load("@rules_python//python:defs.bzl", "py_binary")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load("@py_deps//:requirements.bzl", "requirement")

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

py_binary(
    name = "tool",
    srcs = ["tool.py"],
    data = [":appimage_runtime"],
    python_version = "PY3",
    visibility = ["//visibility:public"],
    deps = [
        "@rules_python//python/runfiles",
        requirement("click"),
    ],
)
