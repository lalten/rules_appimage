"""Prepare and build an AppImage AppDir Mksquashfs pseudo-file definitions file."""

from __future__ import annotations

import argparse
import copy
import functools
import json
import os
import re
import shutil
import sys
from pathlib import Path
from typing import TYPE_CHECKING, NamedTuple

if TYPE_CHECKING:
    from collections.abc import Sequence


class _ManifestCopy(NamedTuple):
    dst: str
    src: str


class _ManifestLink(NamedTuple):
    linkname: str
    target: str


class _ManifestFilesToRun(NamedTuple):
    repo_mapping_basename: str
    runfiles_manifest_short_path: str


class _ManifestData(NamedTuple):
    empty_files: list[str]
    files: list[_ManifestCopy]
    files_to_run: _ManifestFilesToRun
    symlinks: list[_ManifestLink]
    relative_symlinks: list[_ManifestLink]
    tree_artifacts: list[_ManifestCopy]

    @classmethod
    def from_json(cls, data: str) -> _ManifestData:
        data_dict = json.loads(data)
        return cls(
            empty_files=data_dict.get("empty_files", []),
            files=[_ManifestCopy(**entry) for entry in data_dict.get("files", [])],
            symlinks=[_ManifestLink(**entry) for entry in data_dict.get("symlinks", [])],
            relative_symlinks=[_ManifestLink(**entry) for entry in data_dict.get("relative_symlinks", [])],
            files_to_run=_ManifestFilesToRun(**data_dict["files_to_run"]),
            tree_artifacts=[_ManifestCopy(**entry) for entry in data_dict.get("tree_artifacts", [])],
        )


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
      * Value of --sandbox_base (https://bazel.build/reference/command-line-reference#flag--sandbox_base)

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
      * /dev/shm/bazel-sandbox.277e512ed83200b5843e391c89fecc1ab63ff26e90f824a17a37de8c321621eb/linux-sandbox/334/
        execroot/_main/bazel-out/stable-status.txt
        with --sandbox_base=/dev/shm

    The "linux-sandbox/N/execroot" part comes from https://github.com/bazelbuild/bazel/blob/7.3.2/src/main/java/com/google/devtools/build/lib/sandbox/LinuxSandboxedSpawnRunner.java#L250

    We do some best-effort heuristic here to figure out the output base location.
    """
    version_file = Path("bazel-out/stable-status.txt")
    abs_version_file = version_file.absolute().resolve()
    execroot = abs_version_file.parent.parent.parent
    if execroot == Path("/tmp/bazel-working-directory"):
        # --incompatible_sandbox_hermetic_tmp
        # See https://github.com/bazelbuild/bazel/blob/7.1.1/src/main/java/com/google/devtools/build/lib/sandbox/LinuxSandboxedSpawnRunner.java#L76
        output_base = Path("/tmp/bazel-source-roots/")
    elif len(execroot.parts) >= 4 and execroot.parts[-4] == "sandbox":
        # --noincompatible_sandbox_hermetic_tmp, --sandbox_base empty
        # "sandbox" comes from https://github.com/bazelbuild/bazel/blob/7.3.2/src/main/java/com/google/devtools/build/lib/sandbox/SandboxModule.java#L123
        # strip off the "sandbox/linux-sandbox/123/execroot" part
        output_base = execroot.parents[3]
    elif len(execroot.parts) >= 4 and re.match("bazel-sandbox.[0-9a-f]{64}", execroot.parts[-4]):
        # --sandbox_base=/dev/shm
        # The "bazel-sandbox.27[...]eb" part comes from https://github.com/bazelbuild/bazel/blob/7.3.2/src/main/java/com/google/devtools/build/lib/sandbox/SandboxModule.java#L125-L130
        # We can't derive the output base from stable-status.txt in this case as it's a generated file.
        # We'll use this source file itself as we know the path relative to the output base.
        # __file__ is something like
        #   /dev/shm/bazel-sandbox.27[...]eb/linux-sandbox/474/execroot/_main/bazel-out/k8-opt-exec-ST-d57f47055a04/bin/
        # appimage/private/mkappimage.runfiles/_main/appimage/private/mkappdir.py
        # and is a symlink that points at
        #   /home/laurenz/.cache/bazel/_bazel_laurenz/8a8[....]a3f/execroot/_main/appimage/private/mkappdir.py
        # We'll strip the last 5 parts to get the output base.
        assert __file__.endswith("appimage/private/mkappdir.py")
        file = Path(__file__)
        assert file.is_symlink()
        link = file.readlink()
        assert link.is_absolute()
        output_base = file.readlink().parents[4]
    else:
        # --spawn_strategy=local
        output_base = execroot.parent
    return os.fspath(output_base)


def is_inside_bazel_cache(path: Path) -> bool:
    """Check whether a path is inside the Bazel cache."""
    return os.fspath(path).startswith(get_output_base())


def get_all_parent_dirs(path: Path | str) -> list[Path]:
    path = Path(path)
    parts = path.parts if path.is_dir() else path.parts[:-1]
    return [Path(*parts[: i + 1]) for i in range(len(parts))]


def to_pseudofile_def_lines(src: Path, dst: Path, preserve_symlinks: bool) -> dict[str, str]:
    """Return a pseudo-file definition line for a file or directory.

    See https://github.com/plougher/squashfs-tools/blob/d8cb82d/USAGE#L753
    and https://github.com/plougher/squashfs-tools/blob/d8cb82d/examples/pseudo-file.example

    Pseudo file definition formats used here:
    "filename d mode uid gid"               create a directory
    "filename f mode uid gid command"       create file from stdout of command
    "filename h filename"                   create file from copy (hard-link) of filename
    "filename s mode uid gid symlink"       create a symbolic link (mode is ignored)
    """
    operations = {dir.as_posix(): "d 755 0 0" for dir in get_all_parent_dirs(dst)}
    if (
        src.is_symlink()
        and (preserve_symlinks or not src.readlink().exists())
        and not is_inside_bazel_cache(src.readlink())
    ):
        operations[dst.as_posix()] = f"s 0 0 0 {src.readlink()}"
    elif src.is_file():
        operations[dst.as_posix()] = f'h "{src}"'
    elif src.is_dir():
        operations[dst.as_posix()] = f"d {src.lstat().st_mode & 0o777:o} 0 0"
    elif not src.exists():
        raise FileNotFoundError(f"{src=} does not exist")
    else:
        raise NotImplementedError(f"Cannot handle {src}")

    return operations


def copy_file_or_dir(src: Path, dst: Path, preserve_symlinks: bool) -> dict[str, str]:
    """Copy a file or dir from src to dst."""
    if not src.is_dir():
        return to_pseudofile_def_lines(src, dst, preserve_symlinks)

    operations: dict[str, str] = {}

    # Scan and recreate symlinks manually
    links = {link for link in src.rglob("*") if link.is_symlink()}
    for link in links:
        operations.update(to_pseudofile_def_lines(link, dst / link.relative_to(src), preserve_symlinks))

    copies: dict[str, str] = {}
    shutil.copytree(
        src,
        dst,
        symlinks=preserve_symlinks,
        ignore=lambda dir, names: [f for f in names if Path(dir) / f in links],
        copy_function=lambda src, dst: copies.setdefault(dst, src),
        ignore_dangling_symlinks=False,
        dirs_exist_ok=True,
    )
    for dst_, src_ in copies.items():
        operations.update(to_pseudofile_def_lines(Path(src_), Path(dst_), preserve_symlinks))

    return operations


def _move_relative_symlinks_in_files_to_their_own_section(manifest_data: _ManifestData) -> _ManifestData:
    """Check if a file is a _relative_ symlink and if so, move it to a new relative_symlinks section."""
    new_manifest_data = copy.deepcopy(manifest_data)
    new_manifest_data.files.clear()
    new_manifest_data.relative_symlinks.clear()
    files_that_will_exist = {entry.dst for entry in manifest_data.files}
    dirs_that_will_exist: set[str] = set()
    for file in files_that_will_exist:
        dirs_that_will_exist.update(map(str, get_all_parent_dirs(file)))

    for entry in manifest_data.files:
        src = Path(entry.src)

        if not src.is_symlink():
            # This is not a symlink. We want to copy that regular file (or dir!) as-is.
            new_manifest_data.files.append(entry)
            continue

        target = src.readlink()

        while target.is_symlink() and is_inside_bazel_cache(target):
            # This is a symlink residing inside the Bazel cache. Follow it to find where it actually points.
            # Example: src "external/rules_appimage_python_x86_64-unknown-linux-gnu/bin/2to3" is a symlink with target
            # "/home/user/.cache/bazel/_bazel_user/a5a...2f3/execroot/rules_appimage/external/rules_appimage_python_x86_
            # 64-unknown-linux-gnu/bin/2to3" (in Bazel 6) or "/tmp/bazel-source-roots/2/bin/2to3" (in Bazel 7), which
            # itself is a symlink pointing at "2to3-3.11".
            # Loop until we find a symlink chain end or a file that is not inside the Bazel cache.
            # Repository rules may have generated a symlink chain that should be be preserved.
            # Example: libfoo.so -> libfoo.so.1 -> libfoo.so.1.0.
            target = target.readlink()

        if target.is_symlink():
            linkdst = target.readlink()
        else:
            if not target.is_absolute():
                # This was a relative symlink that we resolved in the last step already.
                linkdst = target
            else:
                # The src is a symlink pointing to the a regular file in the Bazel cache.
                new_manifest_data.files.append(entry)
                continue

        if linkdst.is_absolute():
            # Absolute symlinks are ok to keep in the files section because we are going to resolve them before copying.
            # Commonly this happens with source files that are symlinks from the sandbox to the actual source checkout.
            new_manifest_data.files.append(entry)
        else:
            # This is a relative symlink. Let's move it out of the files section and into the relative_symlinks section.
            # We do this to maintain the existing symlink structure and to prevent the linked file to be copied twice
            # (although squashfs would deduplicate it).
            # Note that the link target may _not_ be reachable if it is not declared as input itself.
            # Users need to ensure that whatever shall be available at runtime is properly declared as data dependency.
            full_linkdest = (Path(entry.dst).parent / linkdst).as_posix()
            if Path(entry.src).is_dir():
                will_exist = os.path.normpath(full_linkdest) in dirs_that_will_exist
            else:
                will_exist = full_linkdest in files_that_will_exist
            is_supposed_to_be_dangling = not Path(entry.src).exists()
            if not will_exist and not is_supposed_to_be_dangling:
                # Would create a symlink that points to a file or dir which will not exist in the AppDir.
                # This can happen in situations where
                # .../foo.runfiles/_main/_solib_k8/_U_A_A_Umain~_Urepo_Urules~foo_S_S_Clibfoo.so___Ulib/libfoo.so
                # is a symlink pointing to "libfoo.so.12" but which will not exist in the same dir but instead lives in
                # .../foo.runfiles/_main/_solib_k8/_U_A_A_Umain~_Urepo_Urules~foo_S_S_Clibfoo.so.12___Ulib/libfoo.so.12
                # For now we just don't create a symlink but copy the resolved file instead. mksquashfs will deduplicate
                # it so no additional storage is needed regardless of file size (unless extracted).
                # The downside is that the symlink structure will not look the same as in the source.
                new_manifest_data.files.append(entry)
            else:
                # Create the entry as relative symlink
                new_manifest_data.relative_symlinks.append(_ManifestLink(linkname=entry.dst, target=os.fspath(linkdst)))

    return new_manifest_data


def _prevent_duplicate_dsts_with_diverging_srcs(manifest_data: _ManifestData) -> _ManifestData:
    """Remove duplicate dsts with in the manifest and fail if the srcs would have diverging contents."""
    new_manifest_data = copy.deepcopy(manifest_data)
    new_manifest_data.files.clear()
    dst_to_src: dict[str, str] = {}
    for file in manifest_data.files:
        if file.dst not in dst_to_src:
            dst_to_src[file.dst] = file.src
            new_manifest_data.files.append(file)
        else:
            this_src = Path(file.src).read_bytes()
            other_src = Path(dst_to_src[file.dst]).read_bytes()
            if this_src != other_src:
                # this is likely a runfile of a transitioned binary that's also present in untransitioned form.
                # We shouldn't try to overwrite it because generated files are read-only.
                raise NotImplementedError(f"Got more than one {file.dst=} with different contents")
    return new_manifest_data


def make_appdir_pseudofile_defs(manifest: Path, runfiles_manifest: Path) -> dict[str, str]:
    """Make the AppDir that will be squashfs'd into the AppImage.

    Note that the [AppImage Type2 Spec][appimage-spec] specifies that the contained [AppDir][appdir-spec] may contain a
    [.desktop file][desktop-spec]. To my knowledge this is only used with [appimaged][appimaged] and entirely optional.

    [appdir-spec]: https://rox.sourceforge.net/desktop/AppDirs.html
    [appimage-spec]: https://github.com/AppImage/AppImageSpec/blob/master/draft.md
    [desktop-spec]: https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html
    [appimaged]: https://docs.appimage.org/user-guide/run-appimages.html#integrating-appimages-into-the-desktop
    """
    manifest_data = _ManifestData.from_json(manifest.read_text())
    manifest_data = _move_relative_symlinks_in_files_to_their_own_section(manifest_data)
    manifest_data = _prevent_duplicate_dsts_with_diverging_srcs(manifest_data)

    # Generate a runfiles_manifest (target.runfiles/MANIFEST file) that contains nothing but the pointer to the
    # "_repo_mapping" runfile. This is required by the rules_cc runfiles library to find the target.repo_mapping file.
    # We can not use the original MANIFEST file as generated by Bazel as it contains absolute paths that will break
    # when the Appimage is moved to another machine or container.
    runfiles_manifest.write_text(f"_repo_mapping ../../{manifest_data.files_to_run.repo_mapping_basename}\n")
    runfiles_manifest_dst = manifest_data.files_to_run.runfiles_manifest_short_path
    manifest_data.files.append(_ManifestCopy(src=runfiles_manifest.as_posix(), dst=runfiles_manifest_dst))

    operations: dict[str, str] = {}

    for empty_file in manifest_data.empty_files:
        # example entry: "tests/test_py.runfiles/__init__.py"
        for dir in get_all_parent_dirs(empty_file):
            operations[dir.as_posix()] = "d 755 0 0"
        operations[empty_file] = "f 755 0 0 true"

    for file in manifest_data.files:
        # example entry: {"dst": "tests/test_py.runfiles/_main/tests/data.txt", "src": "tests/data.txt"}
        operations.update(copy_file_or_dir(Path(file.src), Path(file.dst), preserve_symlinks=True))

    for link in manifest_data.symlinks:
        # example entry: {"linkname": "tests/test_py", "target": "tests/test_py.runfiles/_main/tests/test_py"}
        # example entry: {"linkname":
        # "tests/test_py.runfiles/_main/../rules_python~0.27.1~python~python_3_11_x86_64-unknown-linux-gnu/bin/python3",
        # "target": "python3.11"}
        linkfile = Path(link.linkname)
        for dir in get_all_parent_dirs(linkfile):
            operations[dir.as_posix()] = "d 755 0 0"
        target = Path(link.target)
        if target.is_absolute():
            # We keep absolute symlinks as is, but make no effort to copy the target into the runfiles as well.
            # Note that not all Bazel remote cache implementations allow absolute symlinks!
            pass
        else:
            # Adapt relative symlinks to point relative to the new linkfile location
            target = relative_path(target, linkfile.parent)
        operations[linkfile.as_posix()] = f"s 0 0 0 {target}"

    for link in manifest_data.relative_symlinks:
        # example entry: {"linkname":
        # "tests/test_py.runfiles/_main/../rules_python~0.27.1~python~python_3_11_x86_64-unknown-linux-gnu/bin/python3",
        # "target": "python3.11"}
        for dir in get_all_parent_dirs(link.linkname):
            operations[dir.as_posix()] = "d 755 0 0"
        operations[link.linkname] = f"s 0 0 0 {link.target}"

    for tree_artifact in manifest_data.tree_artifacts:
        # example entry:
        # {'dst': 'test.runfiles/_main/../rules_pycross~~lock_repos~pdm_deps/_lock/humanize@4.9.0',
        # 'src': 'bazel-out/k8-fastbuild/bin/external/rules_pycross~~lock_repos~pdm_deps/_lock/humanize@4.9.0'}
        operations.update(copy_file_or_dir(Path(tree_artifact.src), Path(tree_artifact.dst), preserve_symlinks=False))

    # Must not have `..` in file names: https://github.com/plougher/squashfs-tools/blob/4.6.1/squashfs-tools/unsquash-1.c#L377
    operations = {os.path.normpath(f): v for f, v in operations.items()}

    return operations


def write_appdir_pseudofile_defs(manifest: Path, apprun: Path, runfiles_manifest: Path, output: Path) -> None:
    """Write a mksquashfs pf file representing the AppDir."""
    pseudofile_defs = make_appdir_pseudofile_defs(manifest, runfiles_manifest)
    lines = [
        f"AppRun h {apprun}",
        *sorted(f'"{k}" {v}' for k, v in pseudofile_defs.items()),
        "",
    ]
    output.write_text("\n".join(lines))


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
    parser.add_argument(
        "--runfiles_manifest",
        required=True,
        type=Path,
        help="Path to write generated MANIFEST file to",
    )
    parser.add_argument("output", type=Path, help="Where to place output AppDir pseudo-file definition file")
    return parser.parse_args(args)


if __name__ == "__main__":
    args = parse_args(sys.argv[1:])
    write_appdir_pseudofile_defs(args.manifest, args.apprun, args.runfiles_manifest, args.output)
