load("@container_structure_test//:defs.bzl", "container_structure_test")
load("@rules_appimage//appimage:appimage.bzl", "appimage", "appimage_test")
load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_test")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

genrule(
    name = "data",
    outs = ["file.txt"],
    cmd = "echo 'data' > $@",
)

cc_test(
    name = "test",
    timeout = "short",
    srcs = ["test.cpp"],
    data = [
        ":file.txt",
        "@appimage_runtime_aarch64//file",
    ],
    deps = ["@rules_cc//cc/runfiles"],
)

appimage_test(
    name = "test.appimage",
    timeout = "short",
    binary = ":test",
    tags = ["requires-fakeroot"],
    target_compatible_with = ["@platforms//os:linux"],
    visibility = [":__subpackages__"],
)

# Ideally we'd reuse test.appimage but until https://github.com/bazelbuild/bazel/issues/21410 is fixed we need to duplicate the targets in a non-testonly config
cc_binary(
    name = "bin",
    srcs = ["//tests/cc_runfiles:test.cpp"],
    data = [
        ":file.txt",
        "@appimage_runtime_aarch64//file",
    ],
    deps = ["@rules_cc//cc/runfiles"],
)

appimage(
    name = "bin.appimage",
    binary = ":bin",
    tags = ["requires-fakeroot"],
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

container_structure_test(
    name = "container_structure_test",
    timeout = "short",
    configs = ["test_appimage_isolated.yaml"],
    image = "container_structure_test_image",
    target_compatible_with = ["@platforms//os:linux"],
)
