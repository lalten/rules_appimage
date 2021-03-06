"""Rule for creating AppImages."""

load("@bazel_skylib//rules:native_binary.bzl", "native_test")
load("@rules_appimage//appimage/private:runfiles.bzl", "collect_runfiles_info")

def _appimage_impl(ctx):
    """Implementation of the appimage rule."""
    tools = depset(
        direct = [ctx.executable._tool],
        transitive = [ctx.attr._tool[DefaultInfo].default_runfiles.files],
    )

    runfile_info = collect_runfiles_info(ctx)
    manifest_file = ctx.actions.declare_file(ctx.attr.name + "-manifest.json")
    ctx.actions.write(manifest_file, json.encode_indent(runfile_info.manifest))
    inputs = depset(
        direct = [ctx.file.icon, manifest_file] + runfile_info.files,
    )

    # TODO: Use Skylib's shell.quote?
    args = [
        "--manifest={}".format(manifest_file.path),
        "--workdir={}".format(runfile_info.workdir),
        "--entrypoint={}".format(runfile_info.entrypoint),
        "--icon={}".format(ctx.file.icon.path),
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
