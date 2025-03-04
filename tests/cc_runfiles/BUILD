load("@rules_appimage//appimage:appimage.bzl", "appimage_test")
load("@rules_cc//cc:defs.bzl", "cc_test")

cc_test(
    name = "test",
    timeout = "short",
    srcs = ["test.cpp"],
    data = ["@appimage_runtime_aarch64//file"],
    deps = ["@rules_cc//cc/runfiles"],
)

appimage_test(
    name = "test.appimage",
    timeout = "short",
    binary = ":test",
    tags = ["requires-fakeroot"],
    target_compatible_with = ["@platforms//os:linux"],
)
