load("@rules_appimage//appimage:appimage.bzl", "appimage")

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
)
