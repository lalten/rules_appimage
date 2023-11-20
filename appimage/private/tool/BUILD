load("@rules_appimage_py_deps//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_binary", "py_library")

py_library(
    name = "mkappimage",
    srcs = ["mkappimage.py"],
    data = ["@squashfs-tools//:mksquashfs"],
    visibility = ["//visibility:public"],
    deps = [requirement("bazel-runfiles")],
)

py_binary(
    name = "tool",
    srcs = ["cli.py"],
    main = "cli.py",
    python_version = "PY3",
    visibility = ["//visibility:public"],
    deps = [":mkappimage"],
)
