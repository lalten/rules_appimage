load("@container_structure_test//:defs.bzl", "container_structure_test")
load("@rules_appimage//appimage:appimage.bzl", "appimage_test")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("@rules_python//python:defs.bzl", "py_test")

py_test(
    name = "test",
    timeout = "short",
    srcs = ["test.py"],
    deps = ["@pdm_deps//:humanize"],
)

appimage_test(
    name = "test.appimage",
    timeout = "short",
    binary = ":test",
    tags = ["requires-fakeroot"],
)

pkg_tar(
    name = "test.appimage.tar",
    testonly = True,
    srcs = [":test.appimage"],
)

oci_image(
    name = "container_structure_test_image",
    testonly = True,
    base = "@python3-slim",
    tars = [":test.appimage.tar"],
)

container_structure_test(
    name = "container_structure_test",
    timeout = "short",
    configs = ["test_appimage_isolated.yaml"],
    image = "container_structure_test_image",
)
