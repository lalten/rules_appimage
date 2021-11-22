load("@rules_python//python:defs.bzl", "py_test")
load("@py_deps//:requirements.bzl", "requirement")

py_test(
    name = "test_tool",
    srcs = ["test_tool.py"],
    deps = [
        requirement("pytest"),
        "//appimage/private/tool",
    ],
)
