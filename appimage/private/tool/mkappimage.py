"""Library to prepare and build AppImages."""

import json
import os
import shutil
import subprocess
import tempfile
import textwrap
from pathlib import Path
from typing import Dict, Iterable, List, NamedTuple, Optional, Tuple

import runfiles as bazel_runfiles


def _get_path_or_raise(path: str) -> Path:
    """Return a Path to a file in the runfiles, or raise FileNotFoundError."""
    runfiles = bazel_runfiles.Create()
    if not runfiles:
        raise FileNotFoundError("Could not find runfiles")
    runfile = files.Rlocation(path)
    if not runfile:
        raise FileNotFoundError(f"Could not find {path} in runfiles")
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


def is_inside_bazel_cache(path: Path) -> bool:
    """Check whether a path is inside the Bazel cache."""
    return "/.cache/bazel/" in os.fspath(path) and "bazel-out" in path.parts


def copy_and_link(src: Path, dst: Path) -> List[Tuple[Path, Path]]:
    """Copy links and files, and return a list of recreated symlinks."""
    dst.parent.mkdir(parents=True, exist_ok=True)

    # Recreate existing symlinks (Note: symlinks only remain inside /dirs/ that are declared as Bazel dep)
    if src.is_symlink():
        link = Path(os.readlink(src))
        dst.symlink_to(link)
        return [(src, dst)]

    # Recurse into dirs
    if src.is_dir():
        dst.mkdir(parents=True, exist_ok=True)  # make dir, even if there are no files in it
        linkpairs: List[Tuple[Path, Path]] = []
        for dirsrc in src.glob("*"):
            dirdst = dst / dirsrc.relative_to(src)
            linkpairs.extend(copy_and_link(dirsrc, dirdst))
        return linkpairs

    # Regular file
    shutil.copy2(src, dst)
    return []


def fix_linkpair(linkpairs: Iterable[Tuple[Path, Path]]) -> None:
    """If the link would break, copy over the target as well."""
    copied_src_targets: Dict[Path, Optional[Path]] = {}
    for src, dst in linkpairs:
        link = Path(os.readlink(src))
        target = (dst.parent / link).resolve()
        target_in_bazel_cache = is_inside_bazel_cache(target)
        if dst.exists() and not target_in_bazel_cache:
            continue
        if existing_copy := copied_src_targets.get(src.resolve(), None):
            dst.unlink()
            dst.symlink_to(existing_copy)
        else:
            copy_dst = dst if target_in_bazel_cache else target
            if copy_dst.exists():
                copy_dst.unlink()
            else:
                copy_dst.parent.mkdir(parents=True, exist_ok=True)
            try:
                shutil.copy2(src.resolve(), copy_dst, follow_symlinks=False)
            except FileNotFoundError:
                pass  # broken symlinks are allowed
            else:
                copied_src_targets[src.resolve()] = copy_dst


def populate_appdir(appdir: Path, params: AppDirParams) -> None:
    """Make the AppDir that will be squashfs'd into the AppImage."""
    appdir.mkdir(parents=True, exist_ok=True)
    manifest_data = json.loads(params.manifest.read_text())

    for empty_file in manifest_data["empty_files"]:
        (appdir / empty_file).parent.mkdir(parents=True, exist_ok=True)
        (appdir / empty_file).touch()

    linkpairs: List[Tuple[Path, Path]] = []
    for file in manifest_data["files"]:
        src = Path(file["src"]).resolve()
        dst = Path(appdir / file["dst"]).resolve()
        linkpairs.extend(copy_and_link(src, dst))
    fix_linkpair(linkpairs)

    for link in manifest_data["symlinks"]:
        linkfile = (appdir / Path(link["linkname"])).resolve()
        linkfile.parent.mkdir(parents=True, exist_ok=True)
        abs_link_target = (appdir / Path(link["target"])).resolve()
        rel_link_target = os.path.relpath(abs_link_target, linkfile.parent)
        linkfile.symlink_to(rel_link_target)

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
