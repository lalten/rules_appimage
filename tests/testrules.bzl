"""Bazel rules that creates specific versions of symlinks."""

def _runfiles_symlink_impl(ctx):
    symlinks_dict = {ctx.attr.name: ctx.file.target}
    runfiles = ctx.runfiles(symlinks = symlinks_dict)
    return [DefaultInfo(runfiles = runfiles)]

runfiles_symlink = rule(
    implementation = _runfiles_symlink_impl,
    attrs = {
        "target": attr.label(mandatory = True, allow_single_file = True),
    },
)

def _declared_symlink_impl(ctx):
    declared_symlink = ctx.actions.declare_symlink(ctx.attr.name)
    ctx.actions.run_shell(
        outputs = [declared_symlink],
        command = " ".join([
            "ln -s",
            repr(ctx.attr.target),
            repr(declared_symlink.path),
        ]),
    )
    return [DefaultInfo(files = depset([declared_symlink]))]

declared_symlink = rule(
    implementation = _declared_symlink_impl,
    attrs = {
        "target": attr.string(mandatory = True),
    },
)
