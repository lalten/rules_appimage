"""Rule for creating AppImages."""

load("@rules_appimage//appimage/private:runfiles.bzl", "collect_runfiles_info")

def _appimage_impl(ctx):
    """Implementation of the appimage rule."""
    tools = depset(
        direct = [ctx.executable._tool],
        transitive = [ctx.attr._tool[DefaultInfo].default_runfiles.files] + [depset(ctx.files.mksquashfs)],
    )
    runfile_info = collect_runfiles_info(ctx)
    manifest_file = ctx.actions.declare_file(ctx.attr.name + "-manifest.json")
    ctx.actions.write(manifest_file, json.encode_indent(runfile_info.manifest))
    inputs = depset(direct = [ctx.file.icon, manifest_file] + runfile_info.files)

    # TODO: Use Skylib's shell.quote?
    args = [
        "--manifest={}".format(manifest_file.path),
        "--workdir={}".format(runfile_info.workdir),
        "--entrypoint={}".format(runfile_info.entrypoint),
        "--icon={}".format(ctx.file.icon.path),
    ]
    if ctx.attr.mksquashfs:
        args.append("--mksquashfs_path={}".format(ctx.file.mksquashfs.path))
    args.extend(["--mksquashfs_arg=" + arg for arg in ctx.attr.build_args])
    args.append(ctx.outputs.executable.path)

    ctx.actions.run(
        mnemonic = "AppImage",
        inputs = inputs,
        env = ctx.attr.build_env,
        executable = ctx.executable._tool,
        arguments = args,
        outputs = [ctx.outputs.executable],
        tools = tools,
    )

    return [
        DefaultInfo(
            executable = ctx.outputs.executable,
            files = depset([ctx.outputs.executable]),
            runfiles = ctx.runfiles(files = [ctx.outputs.executable]),
        ),
        RunEnvironmentInfo(
            environment = ctx.attr.env,
        ),
    ]

_ATTRS = {
    "binary": attr.label(executable = True, cfg = "target"),
    "icon": attr.label(default = "@appimagetool.png//file", allow_single_file = True),
    "mksquashfs": attr.label(default = None, executable = True, allow_single_file = True, cfg = "host"),
    "build_args": attr.string_list(),
    "build_env": attr.string_dict(),
    "_tool": attr.label(default = "//appimage/private/tool", executable = True, cfg = "exec"),
    "env": attr.string_dict(doc = "Runtime environment variables. See https://bazel.build/reference/be/common-definitions#common-attributes-tests"),
}

appimage = rule(
    implementation = _appimage_impl,
    attrs = _ATTRS,
    executable = True,
)

appimage_test = rule(
    implementation = _appimage_impl,
    attrs = _ATTRS,
    test = True,
)
