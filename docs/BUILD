load("//docs:stardoc_rules.bzl", "appimage_bzl_docs", "markdown_docs")

# Generate documentation for .bzl files in the appimage directory
appimage_bzl_docs(
    name = "appimage_rules_doc",
    srcs = glob(["//appimage/**/*.bzl"]),
    # If there are common dependencies for these .bzl files, list them here.
    # For example: deps = ["//appimage:common_lib_label"],
)

# Include the main README.md
markdown_docs(
    name = "project_readme",
    srcs = ["//:README.md"],
)

# You can add more markdown_docs targets for other Markdown files if needed.
# For example, if you have a CONTRIBUTING.md:
# markdown_docs(
#     name = "contributing_guide",
#     srcs = ["//:CONTRIBUTING.md"], # Assuming it's in the root
# )

# Group all generated documentation
filegroup(
    name = "generated_docs",
    srcs = [
        ":appimage_rules_doc_appimage_appimage.md", # Generated from appimage/appimage.bzl
        ":appimage_rules_doc_appimage_private_mkapprun.md", # Generated from appimage/private/mkapprun.bzl
        ":appimage_rules_doc_appimage_private_runfiles.md", # Generated from appimage/private/runfiles.bzl
        ":appimage_rules_doc_appimage_toolchain.md", # Generated from appimage/toolchain.bzl
        ":project_readme_README.md", # Copied from //:README.md
        # Add other generated files here as you add more sources
    ],
    visibility = ["//visibility:public"],
)
