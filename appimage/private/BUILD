load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@rules_python//python:defs.bzl", "py_binary")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

bzl_library(
    name = "mkapprun",
    srcs = ["mkapprun.bzl"],
    visibility = ["//appimage:__subpackages__"],
)

bzl_library(
    name = "runfiles",
    srcs = ["runfiles.bzl"],
    visibility = ["//appimage:__subpackages__"],
)

py_binary(
    name = "mkappdir",
    srcs = ["mkappdir.py"],
    visibility = ["//visibility:public"],
)

sh_binary(
    name = "mkappimage",
    srcs = ["mkappimage.sh"],
    data = [
        ":mkappdir",
        "@squashfs-tools//:mksquashfs",
    ],
    visibility = ["//visibility:public"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)
