"""Test that root_symlinks work (See https://bazel.build/extending/rules#runfiles_symlinks)."""

load("@rules_appimage//appimage:appimage.bzl", "appimage_test")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
load(":root_runfiles_symlink.bzl", "root_runfiles_symlink")

genrule(
    name = "data",
    outs = ["data.txt"],
    cmd = "echo data > $@",
)

root_runfiles_symlink(
    name = "root_symlink_to_data",
    target = ":data.txt",
)

sh_test(
    name = "test",
    size = "small",
    srcs = ["test.sh"],
    data = [
        ":data.txt",
        ":root_symlink_to_data",
    ],
)

appimage_test(
    name = "test.appimage",
    size = "small",
    binary = ":test",
    tags = ["requires-fakeroot"],
    target_compatible_with = ["@platforms//os:linux"],
)
