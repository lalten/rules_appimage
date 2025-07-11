load("@aspect_bazel_lib//lib:docs.bzl", "stardoc_with_diff_test", "update_docs")

stardoc_with_diff_test(
    name = "defs",
    bzl_library_target = "//appimage:defs",
)

update_docs(name = "update")
