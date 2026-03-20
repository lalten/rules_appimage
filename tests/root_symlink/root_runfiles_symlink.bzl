"""Create a root runfiles symlink for testing (See https://bazel.build/extending/rules#runfiles_symlinks)."""

def _root_runfiles_symlink_impl(ctx):
    runfiles = ctx.runfiles(root_symlinks = {ctx.attr.name: ctx.file.target})
    return [DefaultInfo(runfiles = runfiles)]

root_runfiles_symlink = rule(
    implementation = _root_runfiles_symlink_impl,
    attrs = {
        "target": attr.label(mandatory = True, allow_single_file = True),
    },
)
