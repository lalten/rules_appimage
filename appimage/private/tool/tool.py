"""Tooling to prepare and build AppImages."""

import json
import os
import shutil
import subprocess
import sys
import tempfile
import textwrap
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

import click
from rules_python.python.runfiles import runfiles

APPIMAGE_TOOL = Path(runfiles.Create().Rlocation("rules_appimage/appimage/private/tool/appimagetool.bin"))


def relative_path(target: Path, origin: Path):
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


def make_appimage(
    manifest: Path,
    workdir: Path,
    entrypoint: Path,
    icon: Path,
    extra_args: Iterable[str],
    output_file: Path,
    quiet: bool,
) -> int:
    """Make an AppImage.

    See cli() for args.

    Returns:
        appimagetool return code
    """
    manifest_data = json.loads(manifest.read_text())
    with tempfile.TemporaryDirectory() as tmpdir_name:
        tmpdir = Path(tmpdir_name)
        appdir = tmpdir / "AppDir"
        appdir.mkdir()

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
            textwrap.dedent(
                f"""\
                #!/bin/sh
                set -eu
                HERE="$(dirname $0)"
                cd "${{HERE}}/{workdir}"
                exec "./{entrypoint}" "$@"
                """
            )
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
                """
            )
        )

        shutil.copy(src=icon, dst=appdir / f"AppRun{icon.suffix}", follow_symlinks=True)

        cmd = [
            os.fspath(APPIMAGE_TOOL),
            *extra_args,
            os.fspath(appdir),
            os.fspath(output_file),
        ]
        proc = subprocess.run(cmd, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if not quiet or proc.returncode:
            print(proc.stdout, file=sys.stderr)
        return proc.returncode


@click.command()
@click.option(
    "--manifest",
    required=True,
    type=click.Path(exists=True, path_type=Path),
    help="Path to manifest json with file and link defintions, e.g. 'bazel-out/k8-fastbuild/bin/tests/appimage_py-manifest.json'",
)
@click.option(
    "--workdir",
    required=True,
    type=click.Path(path_type=Path),
    help="Path to working dir, e.g. 'AppDir/tests/test_py.runfiles/rules_appimage'",
)
@click.option(
    "--entrypoint",
    required=True,
    type=click.Path(path_type=Path),
    help="Path to entrypoint, e.g. 'AppDir/tests/test_py'",
)
@click.option(
    "--icon",
    required=True,
    type=click.Path(exists=True, path_type=Path),
    help="Icon to use in the AppImage, e.g. 'external/AppImageKit/resources/appimagetool.png'",
)
@click.option(
    "--extra_arg",
    "extra_args",
    required=False,
    multiple=True,
    help="Any extra arg to pass to appimagetool, e.g. '--no-appstream'. Can be used multiple times.",
)
@click.option(
    "--quiet",
    is_flag=True,
    show_default=True,
    help="Don't print appimagetool output unless there is an error",
)
@click.argument(
    "output",
    type=click.Path(path_type=Path),
)
def cli(
    manifest: Path,
    workdir: Path,
    entrypoint: Path,
    icon: Path,
    extra_args: Tuple[str],
    quiet: bool,
    output: Path,
) -> None:
    """Tool for rules_appimage.

    Writes the built AppImage to OUTPUT.
    """
    sys.exit(make_appimage(manifest, workdir, entrypoint, icon, extra_args, output, quiet))


if __name__ == "__main__":
    cli()
