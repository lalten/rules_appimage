load("@rules_appimage//appimage:appimage.bzl", "appimage_test")
load("@rules_cc//cc:defs.bzl", "cc_test")

exports_files(["test.cpp"])

genrule(
    name = "data",
    outs = ["file.txt"],
    cmd = "echo 'data' > $@",
    visibility = [":__subpackages__"],
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
)
