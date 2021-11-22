"""Rule for creating AppImages."""

load("@bazel_skylib//rules:native_binary.bzl", "native_test")

def _appimage_impl(ctx):
    """Implementation of the appimage rule."""
    manifest = ctx.attr.binary[DefaultInfo].files_to_run.runfiles_manifest
    inputs = depset(
        direct = [
            ctx.executable.binary,
            ctx.file.icon,
        ] + ([manifest] if manifest else []),
        # Need to explicitly depend on runfiles or they may not be generated/available when stealing the .runfiles dir.
        transitive = [ctx.attr.binary[DefaultInfo].default_runfiles.files],
    )

    tools = depset(
        direct = [ctx.executable._tool],
        transitive = [ctx.attr._tool[DefaultInfo].default_runfiles.files],
    )

    # TODO: Use Skylib's shell.quote?
    args = [
        "--app={}".format(ctx.executable.binary.path),
        "--app_path={}".format(ctx.attr.binary.label.package + "/" + ctx.attr.binary.label.name),
        "--runfiles_manifest={}".format(manifest.path if manifest else ""),
        "--icon={}".format(ctx.file.icon.path),
        "--workspace_name={}".format(ctx.attr.binary.label.workspace_name or ctx.workspace_name),
    ]
    args.extend(["--extra_arg=" + arg for arg in ctx.attr.build_args])
    if ctx.attr.quiet:
        args.append("--quiet")
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

appimage = rule(
    implementation = _appimage_impl,
    attrs = {
        "binary": attr.label(
            executable = True,
            cfg = "target",
        ),
        "icon": attr.label(
            default = "@AppImageKit//:resources/appimagetool.png",
            allow_single_file = True,
        ),
        "build_args": attr.string_list(
            default = [
                "--appimage-extract-and-run",
                "--no-appstream",
            ],
        ),
        "build_env": attr.string_dict(
            default = {
                "ARCH": "x86_64",
                "NO_CLEANUP": "1",
            },
        ),
        "quiet": attr.bool(
            default = True,
        ),
        "_tool": attr.label(
            default = "//appimage/private/tool",
            executable = True,
            cfg = "exec",
        ),
    },
    executable = True,
)

def appimage_test(name, **kwargs):
    """AppImage test rule."""
    appimage(
        name = name + ".AppImage",
        **kwargs
    )

    native_test(
        name = name,
        args = ["--appimage-extract-and-run"],
        src = name + ".AppImage",
        out = name + ".AppImage.test",
    )
