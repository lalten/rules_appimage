"""Bazel rules that creates specific versions of symlinks."""

load("@rules_cc//cc:defs.bzl", "cc_binary")
load("@with_cfg.bzl", "with_cfg")

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
    runfiles = ctx.runfiles(files = [declared_symlink])
    return [DefaultInfo(runfiles = runfiles)]

declared_symlink = rule(
    implementation = _declared_symlink_impl,
    attrs = {
        "target": attr.string(mandatory = True),
    },
)

_transition_builder = with_cfg(cc_binary)
_transition_builder.extend("copt", ["-O1"])

transitioned_cc_binary, _transitioned_cc_binary_reset = _transition_builder.build()
