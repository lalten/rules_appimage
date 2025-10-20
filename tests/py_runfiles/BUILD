load("@rules_appimage_py_deps//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_test")
load("//appimage:appimage.bzl", "appimage_test")

py_test(
    name = "test",
    timeout = "short",
    srcs = ["test.py"],
    data = ["@appimage_runtime_aarch64//file"],
    deps = [
        requirement("pytest"),
        "@rules_python//python/runfiles",
    ],
)

appimage_test(
    name = "appimage_test",
    timeout = "short",
    binary = ":test",
    env = {"APPIMAGE_EXTRACT_AND_RUN": "1"},
    target_compatible_with = ["@platforms//os:linux"],
)
