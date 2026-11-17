load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
load("//appimage:appimage.bzl", "appimage")

sh_binary(
    name = "main",
    srcs = ["main.sh"],
)

sh_binary(
    name = "alt",
    srcs = ["alt.sh"],
    data = [
        "alt_data.txt",
        "@bazel_skylib//:LICENSE",
    ],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

appimage(
    name = "test.appimage",
    argv0_binaries = {
        "alt": ":alt",
        "it's alt": ":alt",
        "wheelmaker": "@rules_python//tools:wheelmaker",  # py_binary from an external repo
    },
    binary = ":main",
)

sh_test(
    name = "test",
    timeout = "short",
    srcs = ["test.sh"],
    data = [":test.appimage"],
    tags = ["requires-fakeroot"],
    target_compatible_with = ["@platforms//os:linux"],
)
