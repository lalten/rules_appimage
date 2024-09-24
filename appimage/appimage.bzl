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
    inputs = depset(direct = [manifest_file, apprun] + runfile_info.files)

    # Create the AppDir mksquashfs pseudofile definitions
    pseudofile_defs = ctx.actions.declare_file(ctx.attr.name + ".pseudofile_defs.txt")
    args = ctx.actions.args()
    args.add("--manifest").add(manifest_file.path)
    args.add("--apprun").add(apprun.path)
    args.add(pseudofile_defs.path)
    ctx.actions.run(
        mnemonic = "MkAppDir",
        inputs = inputs,
        executable = ctx.executable._mkappdir,
        arguments = [args],
        outputs = [pseudofile_defs],
        execution_requirements = {"no-remote-exec": "1"},
    )

    # Create an empty directory that we can point mksquashfs at so all the added files come from the pseudofile defs
    emptydir = ctx.actions.declare_directory(ctx.attr.name + ".emptydir")
    ctx.actions.run_shell(
        mnemonic = "MkEmptyDir",
        outputs = [emptydir],
        command = "mkdir -p %s" % emptydir.path,
    )

    # Create the AppDir squashfs
    appdirsqfs = ctx.actions.declare_file(ctx.attr.name + ".sqfs")
    mksquashfs_args = ctx.actions.args()
    mksquashfs_args.add(emptydir.path + "/")
    mksquashfs_args.add(appdirsqfs.path)
    mksquashfs_args.add_all(MKSQUASHFS_ARGS)
    mksquashfs_args.add("-processors").add(MKSQUASHFS_NUM_PROCS)
    mksquashfs_args.add("-mem").add("%sM" % MKSQUASHFS_MEM_MB)
    mksquashfs_args.add_all(ctx.attr.build_args)
    mksquashfs_args.add("-pf").add(pseudofile_defs.path)
    ctx.actions.run(
        mnemonic = "MkSquashfs",
        inputs = depset(direct = [pseudofile_defs, apprun, emptydir] + runfile_info.files),
        executable = ctx.executable._mksquashfs,
        arguments = [mksquashfs_args],
        tools = [ctx.executable._mksquashfs],
        outputs = [appdirsqfs],
        resource_set = _resources,
        execution_requirements = {"no-remote-cache": "1"},
    )

    # Create the Appimage
    ctx.actions.run_shell(
        mnemonic = "AppImage",
        inputs = [toolchain.appimage_runtime, appdirsqfs],
        command = "cat $1 $2 >$3",
        arguments = [
            toolchain.appimage_runtime.path,
            appdirsqfs.path,
            ctx.outputs.executable.path,
        ],
        outputs = [ctx.outputs.executable],
        execution_requirements = {"no-remote-exec": "1"},
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
    "_mkappdir": attr.label(default = "//appimage/private:mkappdir", executable = True, cfg = "exec"),
    "_mksquashfs": attr.label(default = "@squashfs-tools//:mksquashfs", executable = True, cfg = "exec"),
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
