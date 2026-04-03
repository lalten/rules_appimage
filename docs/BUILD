load("@stardoc//stardoc:stardoc_with_diff_test.bzl", "stardoc_with_diff_test", "update_docs")

stardoc_with_diff_test(
    name = "defs",
    bzl_library_target = "//appimage:defs",
    out_label = "defs.md",
)

update_docs(name = "update")
