"""A test program to be packaged as an appimage."""

import argparse
import os
import subprocess
from pathlib import Path

_TMPDIR = os.environ.get("TEST_TMPDIR", "")
assert _TMPDIR
_ENV = os.environ.copy()
_ENV.update({"TMPDIR": _TMPDIR})


def test_datadep() -> None:
    """Test that the data dependency of the binary is bundled."""
    data_dep = Path("tests/data.txt")
    assert data_dep.is_file(), f"{data_dep} does not exist"
    assert (size := data_dep.stat().st_size) == 591, f"{data_dep} has wrong size {size}"


def test_appimage_datadep() -> None:
    """Test that data deps to the appimage itself are bundled."""
    data_dep = Path("tests/appimage_data_file.txt")
    assert data_dep.is_file(), f"{data_dep} does not exist"
    assert (size := data_dep.stat().st_size) == 13, f"{data_dep} has wrong size {size}"

    data_dep = Path("tests/appimage_data_filegroup.txt")
    assert data_dep.is_file(), f"{data_dep} does not exist"
    assert (size := data_dep.stat().st_size) == 22, f"{data_dep} has wrong size {size}"


def test_external_bin() -> None:
    """Test that the external binary is bundled."""
    external_bin_appimage = Path.cwd() / "tests/external_bin.appimage"
    assert external_bin_appimage.is_file()
    assert os.access(external_bin_appimage, os.X_OK)
    cmd = [os.fspath(external_bin_appimage), "--appimage-extract-and-run", "--help"]
    proc = subprocess.run(
        cmd,
        text=True,
        check=False,
        stderr=subprocess.STDOUT,
        stdout=subprocess.PIPE,
        cwd=_TMPDIR,
        env=_ENV,
    )
    assert "Builds a python wheel" in proc.stdout, proc.stdout


def test_symlinks() -> None:
    """Test that symlinks are handled correctly."""
    link_to_undeclared_dep = Path("tests/dir/link_to_file_in_dir2")
    assert link_to_undeclared_dep.is_symlink()
    assert not link_to_undeclared_dep.resolve().exists()

    link_to_link_to_undeclared_dep = Path("tests/dir/link_to_link_to_file_in_dir2")
    assert link_to_link_to_undeclared_dep.is_symlink()
    target = link_to_link_to_undeclared_dep.readlink()
    linkdir = link_to_link_to_undeclared_dep.parent
    assert (linkdir / target).is_symlink(), f"{linkdir} / {target} is not a link as expected"
    assert not (linkdir / target).resolve().is_file()

    link_to_declared_dep = Path("tests/dir/subdir/symlink_to_local_file")
    assert link_to_declared_dep.is_file()
    assert link_to_declared_dep.is_symlink()
    assert os.readlink(link_to_declared_dep) == "../local_file"

    abs_link = Path("tests/dir/link_to_bin_sh")
    assert abs_link.is_file()
    assert abs_link.is_symlink()
    assert os.readlink(abs_link) == "/bin/sh"

    dir_link = Path("tests/dir/subdir/dir_link")
    assert dir_link.is_symlink()
    assert os.readlink(dir_link) == "dir"
    assert dir_link.resolve().is_dir()

    link = next(Path("..").glob("**/bin/python3"))
    # link will be one of these depending on --enable_bzlmod (and rules_python version)
    # "rules_appimage_python_x86_64-unknown-linux-gnu/bin/python3"
    # "rules_python~0.27.1~python~python_3_11_x86_64-unknown-linux-gnu/bin/python3"
    assert link.is_symlink()
    assert os.readlink(link) == "python3.11"


def test_declared_symlinks() -> None:
    """Test that symlinks declared via `ctx.actions.declare_symlink(...)` are handled correctly."""
    link = Path("tests/dangling_symlink")
    assert link.is_symlink()
    target = os.readlink(link)
    assert target == "../idonotexist", target
    assert not link.is_file()

    link = Path("tests/dot_symlink")
    assert link.is_symlink()
    target = os.readlink(link)
    assert target == ".", target
    assert link.is_dir()

    link = Path("tests/dotdot_symlink")
    assert link.is_symlink()
    target = os.readlink(link)
    assert target == "..", target
    assert link.is_dir()


def test_runfiles_symlinks() -> None:
    """Test that symlinks coming from `ctx.runfiles(symlinks = {...})` are handled correctly."""
    runfiles_symlink = Path("path/to/the/runfiles_symlink")
    assert runfiles_symlink.is_symlink()
    assert os.readlink(runfiles_symlink) == "../../../tests/data.txt"
    assert runfiles_symlink.resolve().is_file()


def test_binary_env() -> None:
    """Test that env attr on the binary target is handled."""
    bazel_version = os.getenv("USE_BAZEL_VERSION", "latest")
    if bazel_version.startswith(("latest", "7.")):
        # Bazel >= 7.0.0 does set the RunEnvironmentInfo provider 🎉.
        assert os.getenv("MY_BINARY_ENV") == "propagated only in Bazel 7+"
    else:
        # Otherwise it seems rules_python does not set the RunEnvironmentInfo provider.
        # See https://github.com/bazelbuild/rules_python/issues/901
        val = os.getenv("MY_BINARY_ENV")
        assert val is None, f"Expected env to be missing, but got {val}"


def greeter() -> None:
    """Greet the user."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--name", default="world")
    name = parser.parse_args().name
    print(f"Hello, {name}!")


if __name__ == "__main__":
    test_datadep()
    test_appimage_datadep()
    test_external_bin()
    test_symlinks()
    test_declared_symlinks()
    test_runfiles_symlinks()
    test_binary_env()
    greeter()
