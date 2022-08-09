load("//appimage:appimage.bzl", "appimage", "appimage_test")
load("@rules_python//python:defs.bzl", "py_binary", "py_test")
load("@py_deps//:requirements.bzl", "requirement")

sh_binary(
    name = "test_sh",
    srcs = ["test.sh"],
)

appimage_test(
    name = "appimage_test_sh",
    binary = ":test_sh",
)

py_binary(
    name = "test_py",
    srcs = ["test.py"],
    data = [
        "data.txt",
        "dir",  # this is a relative directory, not a target label
        ":external_bin.appimage",
    ],
    main = "test.py",
    deps = [requirement("click")],
)

appimage_test(
    name = "appimage_test_py",
    binary = ":test_py",
)

appimage(
    name = "appimage_py",
    binary = ":test_py",
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
)
