"""Test appimages as data deps."""

import os
import subprocess
import sys
import platform
from pathlib import Path

import pytest

APPIMAGE = str(Path.cwd() / "tests/appimage_py")
_TMPDIR = os.environ.get("TEST_TMPDIR", "")
assert _TMPDIR
_ENV = os.environ.copy()
_ENV.update({"TMPDIR": _TMPDIR})

# from UNIX file command source: `magic/Magdir/elf`
UNAME_TO_FILE = {
    "x86_64": "x86-64",
    "aarch64": "ARM aarch64",
    "i386": "Intel 80386",
    "armv7l": "ARM",
    "arm": "ARM"
}

def test_file() -> None:
    """Test that the appimage has the expected magic."""
    cmd = ["file", "--dereference", APPIMAGE]
    out = subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE).stdout
    uname_arch = platform.uname().machine
    march = UNAME_TO_FILE[uname_arch]
    expected = f"tests/appimage_py: ELF 64-bit LSB executable, {march}, version 1 (SYSV), statically linked, stripped"
    assert expected in out


def test_run() -> None:
    """Test that the appimage can be run."""
    cmd = [APPIMAGE, "--appimage-extract-and-run", "--name", "Simon Peter"]
    output = subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE, cwd=_TMPDIR, env=_ENV).stdout
    assert output == "Hello, Simon Peter!\n"


def test_symlinks() -> None:
    """Test that the appimage has the expected symlinks and none are broken."""
    cmd = [APPIMAGE, "--appimage-extract"]
    subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE, cwd=_TMPDIR, env=_ENV)
    extracted_path = Path(_TMPDIR) / "squashfs-root"
    symlinks_present = False
    for file in extracted_path.glob("**/*"):
        if file.is_symlink() and file.name != "invalid_link":
            assert file.resolve().exists(), f"{file} resolves to {file.resolve()}, which does not exist!"
            symlinks_present = True
    assert symlinks_present


if __name__ == "__main__":
    sys.exit(pytest.main(["-v", __file__]))
