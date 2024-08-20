"""Prepare and build an AppImage AppDir tarball."""

from __future__ import annotations

import argparse
import copy
import errno
import functools
import json
import os
import shutil
import sys
import tarfile
import tempfile
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import Sequence

    _ManifestDataT = dict[str, list[str | dict[str, str]]]


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


def copy_file_or_dir(src: Path, dst: Path, preserve_symlinks: bool) -> Path:
    """Copy a file or dir from src to dst.

    We use copy2 because it preserves metadata like permissions.
    If preserve_symlinks is True we do not want to set follow_symlinks in order to keep
    symlink targets preserved.
    """
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not src.is_dir():
        return shutil.copy2(src, dst, follow_symlinks=not preserve_symlinks)

    # Scan and recreate dangling symlinks
    dangling: set[Path] = set()
    for link in src.rglob("*"):
        if not link.is_symlink() or link.exists():
            continue
        new_link = dst / link.relative_to(src)
        new_link.parent.mkdir(parents=True, exist_ok=True)
        new_link.symlink_to(link.readlink())
        dangling.add(link)

    copy_function = functools.partial(shutil.copy2, follow_symlinks=not preserve_symlinks)
    return shutil.copytree(
        src,
        dst,
        symlinks=preserve_symlinks,
        ignore=lambda dir, names: [f for f in names if Path(dir) / f in dangling],
        copy_function=copy_function,
        ignore_dangling_symlinks=False,
        dirs_exist_ok=True,
    )


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


def populate_appdir(appdir: Path, manifest: Path) -> None:
    """Make the AppDir that will be squashfs'd into the AppImage.

    Note that the [AppImage Type2 Spec][appimage-spec] specifies that the contained [AppDir][appdir-spec] may contain a
    [.desktop file][desktop-spec]. To my knowledge this is only used with [appimaged][appimaged] and entirely optional.

    [appdir-spec]: https://rox.sourceforge.net/desktop/AppDirs.html
    [appimage-spec]: https://github.com/AppImage/AppImageSpec/blob/master/draft.md
    [desktop-spec]: https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html
    [appimaged]: https://docs.appimage.org/user-guide/run-appimages.html#integrating-appimages-into-the-desktop
    """
    appdir.mkdir(parents=True, exist_ok=True)
    manifest_data = json.loads(manifest.read_text())
    manifest_data = _move_relative_symlinks_in_files_to_their_own_section(manifest_data)

    for empty_file in manifest_data["empty_files"]:
        # example entry: "tests/test_py.runfiles/__init__.py"
        (appdir / empty_file).parent.mkdir(parents=True, exist_ok=True)
        (appdir / empty_file).touch()

    for file in manifest_data["files"]:
        # example entry: {"dst": "tests/test_py.runfiles/_main/tests/data.txt", "src": "tests/data.txt"}
        src = Path(file["src"]).resolve()
        dst = Path(appdir / file["dst"]).resolve()
        if dst.exists():
            # this is likely a runfile of a transitioned binary that's also present in untransitioned form.
            # We shouldn't try to overwrite it because generated files are read-only.
            if src.read_bytes() == dst.read_bytes():
                continue
            else:
                raise NotImplementedError(f"Got more than one {dst=} with different contents")
        assert src.exists(), f"want to copy {src} to {dst}, but it does not exist"
        copy_file_or_dir(src, dst, preserve_symlinks=True)

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

    for tree_artifact in manifest_data["tree_artifacts"]:
        # example entry:
        # {'dst': 'test.runfiles/_main/../rules_pycross~~lock_repos~pdm_deps/_lock/humanize@4.9.0',
        # 'src': 'bazel-out/k8-fastbuild/bin/external/rules_pycross~~lock_repos~pdm_deps/_lock/humanize@4.9.0'}
        src = Path(tree_artifact["src"]).resolve()
        dst = Path(appdir / tree_artifact["dst"]).resolve()
        assert src.exists(), f"want to copy {src} to {dst}, but it does not exist"
        copy_file_or_dir(src, dst, preserve_symlinks=False)


def _make_executable(ti: tarfile.TarInfo) -> tarfile.TarInfo:
    ti.mode |= 0o111
    return ti


def make_appdir_tar(manifest: Path, apprun: Path, output: Path) -> None:
    """Create an AppImage AppDir (uncompressed) tar ready to be sqfstar'ed."""
    with tarfile.open(output, "w") as tar:
        tar.add(apprun.resolve(), arcname="AppRun", filter=_make_executable)
        with tempfile.TemporaryDirectory() as tmpdir:
            appdir = Path(tmpdir)
            populate_appdir(appdir, manifest)
            for top_level in appdir.iterdir():
                tar.add(top_level, arcname=top_level.name)


def parse_args(args: Sequence[str]) -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Prepare and build AppImages.")
    parser.add_argument(
        "--manifest",
        required=True,
        type=Path,
        help="Path to manifest json with file and link definitions, e.g. 'bazel-bin/tests/appimage_py-manifest.json'",
    )
    parser.add_argument(
        "--apprun",
        required=True,
        type=Path,
        help="Path to AppRun script",
    )
    parser.add_argument("output", type=Path, help="Where to place output AppDir tar")
    return parser.parse_args(args)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    make_appdir_tar(args.manifest, args.apprun, args.output)
