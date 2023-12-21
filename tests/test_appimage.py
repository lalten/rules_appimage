"""Test appimages as data deps."""

import os
import platform
import subprocess
import sys
from pathlib import Path

import pytest

APPIMAGE = str(Path.cwd() / "tests/appimage_py")
_TMPDIR = os.environ.get("TEST_TMPDIR", "")
assert _TMPDIR
_ENV = os.environ.copy()
_ENV.update({"TMPDIR": _TMPDIR})

EXPECTED_FILE = {
    "x86_64": "ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, stripped",
    "aarch64": "ELF 64-bit LSB executable, ARM aarch64, version 1 (SYSV), statically linked, stripped",
    "i386": "ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), statically linked, stripped",
    "armv7l": "ELF 32-bit LSB executable, ARM, version 1 (SYSV), statically linked, stripped",
    "arm": "ELF 32-bit LSB executable, ARM, version 1 (SYSV), statically linked, stripped",
}


def test_file() -> None:
    """Test that the appimage has the expected magic."""
    cmd = ["file", "--dereference", APPIMAGE]
    out = subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE).stdout
    uname_arch = platform.uname().machine
    expected = f"tests/appimage_py: {EXPECTED_FILE[uname_arch]}"
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
        if file.is_symlink():
            if file.name in {"relatively_invalid_link", "absolutely_invalid_link"}:
                assert not file.resolve().exists(), f"{file} resolves to {file.resolve()}, which should not exist!"
            else:
                assert file.resolve().exists(), f"{file} resolves to {file.resolve()}, which does not exist!"
            symlinks_present = True
    assert symlinks_present


if __name__ == "__main__":
    sys.exit(pytest.main(["-v", __file__]))
