package(default_visibility = ["//tests:__subpackages__"])

genrule(
    name = "make_libfoo",
    srcs = ["foo.S"],
    outs = [
        "libfoo.so.1",
        "libfoo.so",
    ],
    cmd = "\n".join([
        "$(CC) -nostdlib -fPIC -shared -o $(RULEDIR)/libfoo.so.1 $<",
        "$(STRIP) --strip-unneeded $(RULEDIR)/libfoo.so.1",
        "ln -s libfoo.so.1 $(RULEDIR)/libfoo.so",
    ]),
    target_compatible_with = ["@platforms//os:linux"],
    toolchains = ["@bazel_tools//tools/cpp:current_cc_toolchain"],
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
    alwayslink = True,
)
