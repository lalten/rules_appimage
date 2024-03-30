"""Library to prepare and build AppImages."""

import copy
import functools
import json
import os
import shutil
import subprocess
import tempfile
import textwrap
from pathlib import Path
from typing import Iterable, NamedTuple

import runfiles as bazel_runfiles

_ManifestDataT = dict[str, list[str | dict[str, str]]]


def _get_path_or_raise(path: str) -> Path:
    """Return a Path to a file in the runfiles, or raise FileNotFoundError."""
    runfiles = bazel_runfiles.Create()
    if not runfiles:
        raise FileNotFoundError("Could not find runfiles")
    runfile = runfiles.Rlocation(path)
    if not runfile:
        raise FileNotFoundError(f"Could not find {path} in runfiles")
    if not Path(runfile).exists():
        raise FileNotFoundError(f"{runfile} does not exist")
    return Path(runfile)


MKSQUASHFS = _get_path_or_raise("squashfs-tools/mksquashfs")


class AppDirParams(NamedTuple):
    """Parameters for the AppDir."""

    manifest: Path
    envfile: Path
    workdir: Path
    entrypoint: Path
    icon: Path
    runtime: Path


def relative_path(target: Path, origin: Path) -> Path:
    """Return path of target relative to origin."""
    try:
        return target.resolve().relative_to(origin.resolve())
    except ValueError:  # target does not start with origin
        return Path("..").joinpath(relative_path(target, origin.parent))


@functools.lru_cache
def get_output_base() -> str:
    """Return the location of this Bazel invocation's output_base.

    The "version file" is always generated (via the workspace_status command). A symlink to it exists at a well-known
    path relative to the runfiles dir ("bazel-out/stable-status.txt"). It's actual location is a well-known path inside
    the Bazel output base. We resolve it to learn the absolute location of the output base on this machine.

    The path structure depends on:
      * Custom output_base (https://bazel.build/docs/user-manual#output-base)
      * Execution strategy (https://bazel.build/docs/user-manual#execution-strategy)
      * External dependency management system (WORKSPACE/Bzlmod)
      * Value of --incompatible_sandbox_hermetic_tmp (https://bazel.build/reference/command-line-reference#flag--incompatible_sandbox_hermetic_tmp)

    For example it may resolve to
      * /mnt/data/sandbox/linux-sandbox/82/execroot/_main/bazel-out/stable-status.txt
        with --output_base=/mnt/data
      * /home/laurenz/.cache/bazel/execroot/rules_appimage/bazel-out/stable-status.txt
        with --spawn_strategy=local (i.e. no sandboxing)
      * /home/laurenz/.cache/bazel/sandbox/linux-sandbox/35/execroot/rules_appimage/bazel-out/stable-status.txt
        /home/laurenz/.cache/bazel/sandbox/processwrapper-sandbox/60/execroot/rules_appimage/bazel-out/stable-status.txt
        with --noincompatible_sandbox_hermetic_tmp
      * /tmp/bazel-working-directory/_main/bazel-out/stable-status.txt
        with --incompatible_sandbox_hermetic_tmp

    We do some best-effort heuristic here to figure out the output base location.
    """
    version_file = Path("bazel-out/stable-status.txt")
    abs_version_file = version_file.absolute().resolve()
    execroot = abs_version_file.parent.parent.parent
    if execroot == Path("/tmp/bazel-working-directory"):
        # See https://github.com/bazelbuild/bazel/blob/7.1.1/src/main/java/com/google/devtools/build/lib/sandbox/LinuxSandboxedSpawnRunner.java#L76
        output_base = Path("/tmp/bazel-source-roots/")
    elif len(execroot.parts) >= 4 and execroot.parts[-4] == "sandbox":
        output_base = Path(*execroot.parts[:-4])
    else:
        output_base = execroot.parent
    return os.fspath(output_base)


def is_inside_bazel_cache(path: Path) -> bool:
    """Check whether a path is inside the Bazel cache."""
    return os.fspath(path).startswith(get_output_base())


def _copy_file(src: Path | str, dst: Path | str) -> None:
    """Copy one file from src to dst."""
    # We use copy2 because it preserves metadata like permissions.
    # We do not want follow_symlinks because we want to keep symlink targets preserved.
    shutil.copy2(src, dst, follow_symlinks=False)


def _copy_file_or_dir(src: Path, dst: Path) -> None:
    """Copy a file or dir from src to dst."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.is_dir():
        shutil.copytree(
            src,
            dst,
            symlinks=True,
            copy_function=_copy_file,
            ignore_dangling_symlinks=True,
            dirs_exist_ok=True,
        )
    else:
        _copy_file(src, dst)


def _move_relative_symlinks_in_files_to_their_own_section(manifest_data: _ManifestDataT) -> _ManifestDataT:
    """Check if a file is a _relative_ symlink and if so, move it to a new relative_symlinks section."""
    new_manifest_data = copy.deepcopy(manifest_data)
    new_manifest_data["files"].clear()
    new_manifest_data["relative_symlinks"] = []

    for entry in manifest_data["files"]:
        assert isinstance(entry, dict)
        src = Path(entry["src"])

        if not src.is_symlink():
            # This is not a symlink. We want to copy that regular file (or dir!) as-is.
            new_manifest_data["files"].append(entry)
            continue

        target = src.readlink()

        if target.is_symlink() and is_inside_bazel_cache(target):
            # This is a symlink residing inside the Bazel cache. Follow one level to find where it actually points.
            # Example: src "external/rules_appimage_python_x86_64-unknown-linux-gnu/bin/2to3" is a symlink with target
            # "/home/user/.cache/bazel/_bazel_user/a5a...2f3/execroot/rules_appimage/external/rules_appimage_python_x86_
            # 64-unknown-linux-gnu/bin/2to3" (in Bazel 6) or "/tmp/bazel-source-roots/2/bin/2to3" (in Bazel 7), which
            # itself is a symlink pointing at "2to3-3.11".
            target = target.readlink()

        if target.is_absolute():
            # Absolute symlinks are ok to keep in the files section because we are going to resolve them before copying.
            # Commonly this happens with source files that are symlinks from the sandbox to the actual source checkout.
            new_manifest_data["files"].append(entry)
        else:
            # This is a relative symlink. Let's move it out of the files section and into the relative_symlinks section.
            # We do this to maintain the existing symlink structure and to prevent the linked file to be copied twice
            # (although squashfs would deduplicate it).
            # Note that the link target may _not_ be reachable if it is not declared as input itself.
            # Users need to ensure that whatever shall be available at runtime is properly declared as data dependency.
            new_manifest_data["relative_symlinks"].append(
                {
                    "linkname": entry["dst"],
                    "target": os.fspath(target),
                },
            )

    return new_manifest_data


def populate_appdir(appdir: Path, params: AppDirParams) -> None:
    """Make the AppDir that will be squashfs'd into the AppImage."""
    appdir.mkdir(parents=True, exist_ok=True)
    manifest_data = json.loads(params.manifest.read_text())
    manifest_data = _move_relative_symlinks_in_files_to_their_own_section(manifest_data)

    for empty_file in manifest_data["empty_files"]:
        # example entry: "tests/test_py.runfiles/__init__.py"
        (appdir / empty_file).parent.mkdir(parents=True, exist_ok=True)
        (appdir / empty_file).touch()

    for file in manifest_data["files"]:
        # example entry: {"dst": "tests/test_py.runfiles/_main/tests/data.txt", "src": "tests/data.txt"}
        src = Path(file["src"]).resolve()
        dst = Path(appdir / file["dst"]).resolve()
        assert src.exists(), f"want to copy {src} to {dst}, but it does not exist"
        _copy_file_or_dir(src, dst)

    for link in manifest_data["symlinks"]:
        # example entry: {"linkname": "tests/test_py", "target": "tests/test_py.runfiles/_main/tests/test_py"}
        linkname = Path(link["linkname"])
        linkfile = (appdir / linkname).resolve()
        linkfile.parent.mkdir(parents=True, exist_ok=True)
        target = Path(link["target"])
        if target.is_absolute():
            # We keep absolute symlinks as is, but make no effort to copy the target into the runfiles as well.
            # Note that not all Bazel remote cache implementations allow absolute symlinks!
            pass
        else:
            # Adapt relative symlinks to point relative to the new linkfile location
            target = relative_path(appdir / target, linkfile.parent)
        linkfile.symlink_to(target)

    for link in manifest_data["relative_symlinks"]:
        # example entry: {"linkname":
        # "tests/test_py.runfiles/_main/../rules_python~0.27.1~python~python_3_11_x86_64-unknown-linux-gnu/bin/python3",
        # "target": "python3.11"}
        linkfile = (appdir / link["linkname"]).resolve()
        linkfile.parent.mkdir(parents=True, exist_ok=True)
        target = Path(link["target"])
        assert not target.is_absolute(), f"symlink {linkfile} must be relative, but points at {target}"
        linkfile.symlink_to(target)

    apprun_path = appdir / "AppRun"
    apprun_path.write_text(
        "\n".join(
            [
                "#!/bin/sh",
                # Set up the previously `export -p`ed environment
                *params.envfile.read_text().splitlines(),
                # If running as AppImage outside Bazel, conveniently set BUILD_WORKING_DIRECTORY, like `bazel run` would
                # `$OWD` ("Original Working Directory") is set by the AppImage runtime in
                # https://github.com/lalten/type2-runtime/blob/84f7a00/src/runtime/runtime.c#L1757
                # Note that we can not set BUILD_WORKSPACE_DIRECTORY as it's not known when the AppImage is deployed
                '[ "${BUILD_WORKING_DIRECTORY+1}" ] || export BUILD_WORKING_DIRECTORY="$OWD"',
                # Explicitly set RUNFILES_DIR to the runfiles dir of the binary instead of the appimage rule itself
                f'workdir="$(dirname $0)/{params.workdir}"',
                'export RUNFILES_DIR="$(dirname "${workdir}")"',
                # Run under runfiles
                'cd "${workdir}"',
                # Launch the actual binary
                f'exec "./{params.entrypoint}" "$@"',
            ],
        )
        + "\n",
    )
    apprun_path.chmod(0o751)

    apprun_path.with_suffix(".desktop").write_text(
        textwrap.dedent(
            """\
            [Desktop Entry]
            Type=Application
            Name=AppRun
            Exec=AppRun
            Icon=AppRun
            Categories=Development;
            Terminal=true
            """,
        ),
    )

    shutil.copy(src=params.icon, dst=appdir / f"AppRun{params.icon.suffix or '.png'}", follow_symlinks=True)


def make_squashfs(params: AppDirParams, mksquashfs_params: Iterable[str], output_path: str) -> None:
    """Run mksquashfs to create the squashfs filesystem for the appimage."""
    with tempfile.TemporaryDirectory(suffix="AppDir") as tmpdir_name:
        populate_appdir(appdir=Path(tmpdir_name), params=params)
        cmd = [os.fspath(MKSQUASHFS), tmpdir_name, output_path, "-root-owned", "-noappend", *mksquashfs_params]
        try:
            subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as exc:
            raise RuntimeError(f"Failed to run {' '.join(cmd)!r} (returned {exc.returncode}): {exc.stdout}") from exc


def make_appimage(params: AppDirParams, mksquashfs_params: Iterable[str], output_path: Path) -> None:
    """Make the AppImage by concatenating the AppImage runtime and the AppDir squashfs."""
    shutil.copy2(src=params.runtime, dst=output_path)
    with output_path.open(mode="ab") as output_file, tempfile.NamedTemporaryFile(mode="w+b") as tmp_squashfs:
        make_squashfs(params, mksquashfs_params, tmp_squashfs.name)
        shutil.copyfileobj(tmp_squashfs, output_file)
