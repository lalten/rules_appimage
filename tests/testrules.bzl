"""Bazel rule that creates a runfile symlink."""

def _rules_appimage_test_rule_impl(ctx):
    runfiles = ctx.runfiles(symlinks = {"path/to/the/runfiles_symlink": ctx.files.symlink[0]})
    return [DefaultInfo(runfiles = runfiles)]

rules_appimage_test_rule = rule(
    implementation = _rules_appimage_test_rule_impl,
    attrs = {
        "symlink": attr.label(mandatory = True, allow_single_file = True),
    },
)
