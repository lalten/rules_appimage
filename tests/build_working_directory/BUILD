load("@rules_appimage//appimage:appimage.bzl", "appimage")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

sh_binary(
    name = "entrypoint",
    srcs = ["entrypoint.sh"],
)

appimage(
    name = "test.appimage",
    binary = ":entrypoint",
)

sh_test(
    name = "test",
    timeout = "short",
    srcs = ["test.sh"],
    data = [":test.appimage"],
    tags = ["requires-fakeroot"],
    target_compatible_with = ["@platforms//os:linux"],
)
