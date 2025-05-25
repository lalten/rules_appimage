load("@stardoc//stardoc:stardoc.bzl", "stardoc")

def _stardoc_impl(ctx):
    stardoc(
        name = ctx.attr.name + "_stardoc",
        input = ctx.attr.src,
        out = ctx.attr.name + ".md",
        deps = ctx.attr.deps,
        visibility = ["//visibility:public"],
    )

stardoc_rule = rule(
    implementation = _stardoc_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
        "deps": attr.label_list(allow_empty = True),
    },
)

def appimage_bzl_docs(name, srcs, deps = []):
    for src_file in srcs:
        stardoc_rule(
            name = name + "_" + src_file.replace("/", "_").replace(".bzl", ""),
            src = src_file,
            deps = deps,
        )

def _markdown_doc_impl(ctx):
    out_file = ctx.actions.declare_file(ctx.attr.name + ".md")
    ctx.actions.run_shell(
        inputs = [ctx.file.src],
        outputs = [out_file],
        command = "cp $< $@",
    )
    return [DefaultInfo(files = depset([out_file]))]

markdown_doc_rule = rule(
    implementation = _markdown_doc_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
    },
)

def markdown_docs(name, srcs):
    for src_file_label_str in srcs:
        # Convert label string to a usable name
        file_name = src_file_label_str.split("/")[-1].replace(".md", "")
        markdown_doc_rule(
            name = name + "_" + file_name,
            src = src_file_label_str,
        )
