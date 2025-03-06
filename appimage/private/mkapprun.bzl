"""Implementation of apprun rule."""

load("//appimage/private:runfiles.bzl", "get_entrypoint", "get_workdir")

def _make_env_sh(ctx):
    env_file = ctx.actions.declare_file(ctx.attr.name + "-env.sh")

    # Take the `binary` env and add the appimage target's env on top of it
    env = {}
    if RunEnvironmentInfo in ctx.attr.binary:
        env.update(ctx.attr.binary[RunEnvironmentInfo].environment)
    env.update(ctx.attr.env)

    # Export the current environment to a file so that it can be re-sourced in AppRun
    cmd = " | ".join([
        # Export the current environment, which is a combination of the build env and the user-provided env
        "export -p",
        # Some shells like to use `declare -x` instead of `export`. The build time shell isn't necessarily the same as
        # the runtime shell, so there is no guarantee that `declare` is available at runtime. Let's use `export` instead.
        "sed 's/^declare -x/export/'",
        # Some build-time values are not interesting or even incorrect at AppRun runtime
        "grep -v '^export OLDPWD$$'",
        "grep -v '^export PWD='",
        "grep -v '^export SHLVL='",
        "grep -v '^export TMPDIR='",
    ]) + " > " + env_file.path
    ctx.actions.run_shell(
        outputs = [env_file],
        env = env,
        command = cmd,
    )
    return env_file

def _make_apprun_setup_content(ctx):
    apprun_lines = []

    # The generated AppImage must be able to run outside of Bazel. We conveniently set BUILD_WORKING_DIRECTORY in the
    # to the same value that it would have if the code would be run under `bazel run`. This is important for calculating
    # the actual location of relative paths passed in as user input on command line arguments.
    # We set BUILD_WORKING_DIRECTORY to the first set and not empty value of [BUILD_WORKING_DIRECTORY, OWD, PWD].
    # * $BUILD_WORKING_DIRECTORY (see https://bazel.build/docs/user-manual#running-executables) is set by Bazel in
    #   https://github.com/bazelbuild/bazel/blob/7.1.1/src/main/java/com/google/devtools/build/lib/runtime/commands/RunCommand.java#L548
    #   and is only available when Bazel executes the AppImage for us during bazel run (but not test/coverage).
    # * $OWD ("Original Working Directory") is set by the AppImage runtime in
    #   https://github.com/lalten/type2-runtime/blob/84f7a00/src/runtime/runtime.c#L1757.
    #   When the AppImage is mounted with libfuse its working directory is inside the mount point, which is not the
    #   original working directory of the user. Presumably this is why the AppImage runtime sets OWD only when mounted
    #   with libfuse but *not* when running with APPIMAGE_EXTRACT_AND_RUN=1 or --appimage-extract-and-run. See
    #   https://github.com/AppImage/type2-runtime/issues/23).
    # * $PWD is set by the shell to the current working directory. This is correct if and only if we are not running
    #   under Bazel and not mounted with libfuse, so it is a good value to use as a fallback. It's important to store
    #   $PWD to $BUILD_WORKING_DIRECTORY because we change the working directory to the $RUNFILES_DIR below. This means
    #   that at runtime, $PWD is different to the directory that the user ran the appimage from.
    # This is done with POSIX shell command language ${parameter:-word} "Use Default Values" parameter expansion, see
    # https://pubs.opengroup.org/onlinepubs/009695399/utilities/xcu_chap02.html#tag_02_06_02
    # Note that BUILD_WORKING_DIRECTORY's sibling BUILD_WORKSPACE_DIRECTORY is not of much use here as even if we knew
    # it at build time, it's not guaranteed to be correct or available at runtime.
    apprun_lines.append('OWD="${OWD=$PWD}"')  # remove when https://github.com/AppImage/type2-runtime/issues/23 is fixed
    apprun_lines.append('BUILD_WORKING_DIRECTORY="${BUILD_WORKING_DIRECTORY=$OWD}"')
    apprun_lines.append("export BUILD_WORKING_DIRECTORY")

    # Explicitly set RUNFILES_DIR to the runfiles dir of the binary instead of the appimage rule itself
    apprun_lines.append('thisdir="${0%/*}"')  # Same as "$(dirname "$0")"
    apprun_lines.append('workdir="$thisdir/%s"' % get_workdir(ctx))
    apprun_lines.append('RUNFILES_DIR="${workdir%/*}"')  # Get parent directory of workdir
    apprun_lines.append("export RUNFILES_DIR")

    # Run under runfiles
    apprun_lines.append('cd "$workdir"')

    # Launch the actual binary
    apprun_lines.append('exec "./%s" "$@"' % get_entrypoint(ctx))

    return "\n".join(apprun_lines) + "\n"

def _make_apprun_setup(ctx):
    apprun_script_trailer = ctx.actions.declare_file(ctx.attr.name + "-apprun-setup.sh")
    ctx.actions.write(
        output = apprun_script_trailer,
        content = _make_apprun_setup_content(ctx),
    )
    return apprun_script_trailer

def make_apprun(ctx):
    """Generate the AppRun.

    Args:
        ctx: The context object.

    Returns:
        The generated AppRun file.
    """
    env_file = _make_env_sh(ctx)
    apprun_script_trailer = _make_apprun_setup(ctx)
    apprun_script = ctx.actions.declare_file(ctx.attr.name + ".AppRun.sh")
    ctx.actions.run_shell(
        inputs = [env_file, apprun_script_trailer],
        outputs = [apprun_script],
        arguments = [env_file.path, apprun_script_trailer.path, apprun_script.path],
        command = 'echo "#!/bin/sh" | cat - "$1" "$2" > "$3"',
    )
    apprun_file = ctx.actions.declare_file(ctx.attr.name + ".AppRun")
    ctx.actions.symlink(
        target_file = ctx.file._launch,
        output = apprun_file,
        is_executable = True,
    )
    return apprun_file, apprun_script
