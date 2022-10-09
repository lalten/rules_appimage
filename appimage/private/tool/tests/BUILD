load("@py_deps//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_test")

py_test(
    name = "test_cli",
    srcs = ["test_cli.py"],
    deps = [
        requirement("pytest"),
        "//appimage/private/tool",
    ],
)

py_test(
    name = "test_mkappimage",
    srcs = ["test_mkappimage.py"],
    deps = [
        requirement("pytest"),
        "//appimage/private/tool:mkappimage",
    ],
)
