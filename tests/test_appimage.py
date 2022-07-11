"""Test appimages as data deps."""

import shutil
import subprocess
import sys
from pathlib import Path

import pytest

APPIMAGE = "tests/appimage_py"


def test_file() -> None:
    cmd = ["file", "--dereference", APPIMAGE]
    out = subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE).stdout
    assert out.startswith("tests/appimage_py: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked")


def test_run() -> None:
    cmd = [APPIMAGE, "--appimage-extract-and-run", "--name", "Simon Peter"]
    output = subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE).stdout
    assert output == "Hello, Simon Peter!\n"


def test_symlinks() -> None:
    cmd = [APPIMAGE, "--appimage-extract"]
    try:
        subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE)
        symlinks_present = False
        for file in Path("squashfs-root").glob("**/*"):
            if file.is_symlink():
                assert file.resolve().exists(), f"{file=} resolves to {file.resolve()=}, which does not exist!"
                symlinks_present = True
        assert symlinks_present
    finally:
        shutil.rmtree("squashfs-root")


if __name__ == "__main__":
    sys.exit(pytest.main(["-v", __file__]))
