# docs/tests/BUILD

sh_test(
    name = "docs_smoke_test",
    srcs = ["smoke_test.sh"],
    data = ["//docs:appimage_rules_doc_appimage_appimage.md"], # Depends on one generated doc file
    args = ["$(location //docs:appimage_rules_doc_appimage_appimage.md)"],
)
