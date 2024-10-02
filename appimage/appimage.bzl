"""Rule for creating AppImages."""

load("@rules_appimage//appimage/private:mkapprun.bzl", "make_apprun")
load("@rules_appimage//appimage/private:runfiles.bzl", "collect_runfiles_info")

MKSQUASHFS_ARGS = [
    "-exit-on-error",
    "-no-progress",
    "-quiet",
    "-all-root",
    "-reproducible",
    "-mkfs-time",
    "0",
    "-root-time",
    "0",
    "-all-time",
    "0",
]
MKSQUASHFS_NUM_PROCS = 4
MKSQUASHFS_MEM_MB = 1024

def _resources(*_args, **_kwargs):
    """See https://bazel.build/rules/lib/builtins/actions#run.resource_set."""
    return {"cpu": MKSQUASHFS_NUM_PROCS, "memory": MKSQUASHFS_MEM_MB}

def _appimage_impl(ctx):
    """Implementation of the appimage rule."""
    toolchain = ctx.toolchains["//appimage:appimage_toolchain_type"]

    runfile_info = collect_runfiles_info(ctx)
    manifest_file = ctx.actions.declare_file(ctx.attr.name + ".manifest.json")
    ctx.actions.write(manifest_file, json.encode_indent(runfile_info.manifest))
    apprun = make_apprun(ctx)

    pseudofile_defs = ctx.actions.declare_file(ctx.attr.name + ".pseudofile_defs.txt")
    appdirsqfs = ctx.actions.declare_file(ctx.attr.name + ".sqfs")

    mksquashfs_args = ctx.actions.args()
    mksquashfs_args.add_all(MKSQUASHFS_ARGS)
    mksquashfs_args.add("-processors").add(MKSQUASHFS_NUM_PROCS)
    mksquashfs_args.add("-mem").add("%sM" % MKSQUASHFS_MEM_MB)
    mksquashfs_args.add_all(ctx.attr.build_args)

    ctx.actions.run(
        mnemonic = "AppImage",
        inputs = depset(direct = [manifest_file, apprun, toolchain.appimage_runtime] + runfile_info.files),
        executable = ctx.executable._mkappimage,
        arguments = [
            manifest_file.path,
            apprun.path,
            pseudofile_defs.path,
            appdirsqfs.path,
            toolchain.appimage_runtime.path,
            ctx.outputs.executable.path,
            mksquashfs_args,
        ],
        outputs = [ctx.outputs.executable, pseudofile_defs, appdirsqfs],
        resource_set = _resources,
    )

    # Take the `binary` env and add the appimage target's env on top of it
    env = {}
    if RunEnvironmentInfo in ctx.attr.binary:
        env.update(ctx.attr.binary[RunEnvironmentInfo].environment)
    env.update(ctx.attr.env)

    return [
        DefaultInfo(
            executable = ctx.outputs.executable,
            files = depset([ctx.outputs.executable]),
            runfiles = ctx.runfiles(files = [ctx.outputs.executable]),
        ),
        RunEnvironmentInfo(env),
        OutputGroupInfo(appimage_debug = depset([manifest_file, pseudofile_defs, appdirsqfs])),
    ]

_ATTRS = {
    "binary": attr.label(executable = True, cfg = "target"),
    "build_args": attr.string_list(),
    "data": attr.label_list(allow_files = True, doc = "Any additional data that will be made available inside the appimage"),
    "env": attr.string_dict(doc = "Runtime environment variables. See https://bazel.build/reference/be/common-definitions#common-attributes-tests"),
    "_mkappimage": attr.label(default = "//appimage/private:mkappimage", executable = True, cfg = "exec"),
}

appimage = rule(
    implementation = _appimage_impl,
    attrs = _ATTRS,
    executable = True,
    toolchains = ["//appimage:appimage_toolchain_type"],
)

appimage_test = rule(
    implementation = _appimage_impl,
    attrs = _ATTRS,
    test = True,
    toolchains = ["//appimage:appimage_toolchain_type"],
)
