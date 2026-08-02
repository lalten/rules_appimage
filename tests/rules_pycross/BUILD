load("@bazel_lib//lib:transitions.bzl", "platform_transition_filegroup")
load("@container_structure_test//:defs.bzl", "container_structure_test")
load("@rules_appimage//appimage:appimage.bzl", "appimage")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("@rules_python//python:defs.bzl", "py_binary", "py_test")

py_test(
    name = "test",
    timeout = "short",
    srcs = ["test.py"],
    deps = ["@pdm_deps//:humanize"],
)

py_binary(
    name = "bin",
    srcs = ["test.py"],
    main = "test.py",
    deps = ["@pdm_deps//:humanize"],
)

appimage(
    name = "bin.appimage",
    binary = ":bin",
    target_compatible_with = ["@platforms//os:linux"],
)

pkg_tar(
    name = "bin.appimage.tar",
    srcs = [":bin.appimage"],
)

oci_image(
    name = "container_structure_test_image",
    base = "@python3-slim",
    tars = [":bin.appimage.tar"],
)

platform_transition_filegroup(
    name = "container_structure_test_image_linux",
    srcs = [":container_structure_test_image"],
    target_platform = select({
        "@platforms//cpu:aarch64": "@llvm//platforms:linux_aarch64_musl",
        "//conditions:default": "@llvm//platforms:linux_amd64_musl",
    }),
)

container_structure_test(
    name = "container_structure_test",
    timeout = "short",
    configs = ["test_appimage_isolated.yaml"],
    image = ":container_structure_test_image_linux",
    platform = select({
        "@platforms//cpu:aarch64": "linux/arm64",
        "//conditions:default": "linux/amd64",
    }),
)
