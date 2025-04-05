load("@aspect_bazel_lib//lib:transitions.bzl", "platform_transition_binary", "platform_transition_filegroup")
load("@container_structure_test//:defs.bzl", "container_structure_test")
load("@rules_appimage//appimage:appimage.bzl", "appimage")
load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@rules_oci//oci:defs.bzl", "oci_image")
load("@rules_pkg//pkg:mappings.bzl", "pkg_mklink")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

# Ideally we'd reuse test.appimage but until https://github.com/bazelbuild/bazel/issues/21410 is fixed we need to duplicate the targets in a non-testonly config
cc_binary(
    name = "bin",
    srcs = ["//tests/cc_runfiles:test.cpp"],
    copts = ["-std=c++20"],
    data = [
        "//tests/cc_runfiles:file.txt",
        "@appimage_runtime_aarch64//file",
    ],
    linkopts = ["-static"],  # avoid issues with glibcxx version mismatch inside the container
    deps = ["@rules_cc//cc/runfiles"],
)

appimage(
    name = "bin.appimage",
    binary = ":bin",
    tags = ["requires-fakeroot"],
    target_compatible_with = ["@platforms//os:linux"],
)

# distroless "debug" images contain their shell at /busybox/sh, but the AppRun script uses a "/bin/sh" shebang
pkg_mklink(
    name = "link_sh",
    link_name = "/bin/sh",
    target = "/busybox/sh",
)

pkg_tar(
    name = "link_sh.tar",
    srcs = [":link_sh"],
)

platform_transition_binary(
    name = "bin.appimage.amd64",
    binary = ":bin",
    target_platform = "//:linux_x86_64",
)

pkg_tar(
    name = "bin.appimage.tar",
    srcs = [":bin.appimage.amd64"],
)

oci_image(
    name = "container_structure_test_image",
    base = "@distroless-cc",
    tars = [
        ":link_sh.tar",
        ":bin.appimage.tar",
    ],
)

platform_transition_filegroup(
    name = "container_structure_test_image.amd64",
    srcs = [":container_structure_test_image"],
    target_platform = "//:linux_x86_64",
)

container_structure_test(
    name = "container_structure_test",
    timeout = "short",
    configs = ["test_appimage_isolated.yaml"],
    image = ":container_structure_test_image.amd64",
)
