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

    # Create the AppDir tar
    appdirtar = ctx.actions.declare_file(ctx.attr.name + ".tar")
    args = ctx.actions.args()
    args.add("--manifest").add(manifest_file.path)
    args.add("--apprun").add(apprun.path)
    args.add(appdirtar.path)
    ctx.actions.run(
        mnemonic = "MkAppDir",
        inputs = inputs,
        executable = ctx.executable._mkappdir,
        arguments = [args],
        outputs = [appdirtar],
        execution_requirements = {"no-remote": "1"},
    )

    # Create the AppDir squashfs
    mksquashfs_args = list(MKSQUASHFS_ARGS)
    mksquashfs_args.extend(["-processors", str(MKSQUASHFS_NUM_PROCS)])
    mksquashfs_args.extend(["-mem", "{}M".format(MKSQUASHFS_MEM_MB)])
    mksquashfs_args.extend(ctx.attr.build_args)
    mksquashfs_args.append("-tar")
    appdirsqfs = ctx.actions.declare_file(ctx.attr.name + ".sqfs")
    ctx.actions.run_shell(
        mnemonic = "Sqfstar",
        inputs = [appdirtar],
        command = "{exe} - {dst} {args} <{src}".format(
            exe = ctx.executable._mksquashfs.path,
            dst = appdirsqfs.path,
            args = " ".join(mksquashfs_args),
            src = appdirtar.path,
        ),
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
        execution_requirements = {"no-remote": "1"},
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
        OutputGroupInfo(appimage_debug = depset([manifest_file, appdirtar, appdirsqfs])),
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
