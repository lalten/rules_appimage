load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_import", "cc_library")

package(default_visibility = ["//tests:__subpackages__"])

cc_binary(
    name = "libfoo.so.1",
    srcs = ["foo.S"],
    linkopts = ["-nostdlib"],
    linkshared = True,
    target_compatible_with = ["@platforms//os:linux"],
)

genrule(
    name = "make_libfoo",
    srcs = ["libfoo.so.1"],
    outs = ["libfoo.so"],
    cmd = "ln -s libfoo.so.1 $(RULEDIR)/libfoo.so",
    target_compatible_with = ["@platforms//os:linux"],
)

cc_import(
    name = "libfoo_so",
    shared_library = ":libfoo.so",
)

cc_import(
    name = "libfoo_so_1",
    shared_library = ":libfoo.so.1",
)

cc_library(
    name = "libfoo",
    deps = [
        ":libfoo_so",
        ":libfoo_so_1",
    ],
)
