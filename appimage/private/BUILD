load("@rules_python//python:defs.bzl", "py_binary")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")

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
