load("@py_deps//:requirements.bzl", "requirement")
load("@rules_appimage//appimage:appimage.bzl", "appimage")
load("@rules_python//python:defs.bzl", "py_binary")

py_binary(
    name = "hello",
    srcs = ["hello.py"],
    data = ["//resources"],
    deps = [requirement("click")],
)

appimage(
    name = "hello.appimage",
    binary = ":hello",
)
