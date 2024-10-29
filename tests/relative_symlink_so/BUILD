package(default_visibility = ["//tests:__subpackages__"])

cc_import(
    name = "libfoo10",
    shared_library = "libfoo.so.1.0",
)

cc_import(
    name = "libfoo1",
    shared_library = "libfoo.so.1",
)

cc_import(
    name = "libfoo",
    shared_library = "libfoo.so",
)

cc_library(
    name = "foo",
    deps = [
        ":libfoo",
        ":libfoo1",
        ":libfoo10",
    ],
)
