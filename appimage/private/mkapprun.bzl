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

    # The generated AppImage must be able to run outside of Bazel, so we set BUILD_WORKING_DIRECTORY to what it would
    # be under `bazel run`, which relative command-line paths are resolved against. We use the first set, non-empty
    # value of [BUILD_WORKING_DIRECTORY, OWD, PWD]:
    # * $BUILD_WORKING_DIRECTORY is set by Bazel (https://bazel.build/docs/user-manual#running-executables) only when
    #   Bazel itself executes the AppImage via `bazel run` (not test/coverage).
    # * $OWD ("Original Working Directory") is set by the AppImage runtime when mounted with libfuse, whose own
    #   working directory is inside the mount point rather than the user's original one. It is presumably not set for
    #   APPIMAGE_EXTRACT_AND_RUN=1 / --appimage-extract-and-run (see https://github.com/AppImage/type2-runtime/issues/23).
    # * $PWD is a good fallback: it's correct as long as we're not running under Bazel and not libfuse-mounted. We
    #   save it to BUILD_WORKING_DIRECTORY before changing to $RUNFILES_DIR below, since $PWD itself would then differ
    #   from the directory the user actually ran the appimage from.
    # This uses POSIX shell ${parameter:-word} "Use Default Values" parameter expansion, see
    # https://pubs.opengroup.org/onlinepubs/009695399/utilities/xcu_chap02.html#tag_02_06_02
    apprun_lines.append('OWD="${OWD=$PWD}"')  # remove when https://github.com/AppImage/type2-runtime/issues/23 is fixed
    apprun_lines.append('BUILD_WORKING_DIRECTORY="${BUILD_WORKING_DIRECTORY=$OWD}"')
    apprun_lines.append("export BUILD_WORKING_DIRECTORY")

    # Some environment variables set by Bazel at runtime that interfere with runfiles resolution need to be unset.
    # This can be important when running an AppImage under Bazel (e.g. for integration tests)
    # https://github.com/bazelbuild/bazel/blob/8.4.2/src/main/java/com/google/devtools/build/lib/runtime/commands/RunCommand.java#L193
    apprun_lines.append("unset JAVA_RUNFILES")
    apprun_lines.append("unset RUNFILES_MANIFEST_FILE")
    apprun_lines.append("unset RUNFILES_MANIFEST_ONLY")
    apprun_lines.append("unset TEST_SRCDIR")

    # Explicitly set RUNFILES_DIR to the runfiles dir of the binary instead of the appimage rule itself
    apprun_lines.append('thisdir="$(cd "${0%/*}" && pwd)"')  # Absolute path to the directory containing AppRun
    apprun_lines.append('workdir="$thisdir/%s"' % get_workdir(ctx))
    apprun_lines.append('RUNFILES_DIR="${workdir%/*}"')  # Get parent directory of workdir
    apprun_lines.append("export RUNFILES_DIR")

    # Run under runfiles
    apprun_lines.append('cd "$workdir"')

    # Launch the actual binary
    apprun_lines.append('exec "./%s" "$@"' % get_entrypoint(ctx))

    return "\n".join(apprun_lines) + "\n"

def _make_apprun_setup(ctx):
    apprun_file_trailer = ctx.actions.declare_file(ctx.attr.name + "-apprun-setup.sh")
    ctx.actions.write(
        output = apprun_file_trailer,
        content = _make_apprun_setup_content(ctx),
    )
    return apprun_file_trailer

def make_apprun(ctx):
    """Generate the AppRun.

    Args:
        ctx: The context object.

    Returns:
        The generated AppRun file.
    """
    env_file = _make_env_sh(ctx)
    apprun_file_trailer = _make_apprun_setup(ctx)
    apprun_file = ctx.actions.declare_file(ctx.attr.name + ".AppRun")
    ctx.actions.run_shell(
        inputs = [env_file, apprun_file_trailer],
        outputs = [apprun_file],
        arguments = [env_file.path, apprun_file_trailer.path, apprun_file.path],
        command = 'echo "#!/bin/sh" | cat - "$1" "$2" > "$3"',
    )
    return apprun_file
