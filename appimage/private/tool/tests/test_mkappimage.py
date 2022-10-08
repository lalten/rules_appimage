"""Unit tests for library to prepare and build AppImages."""

import os
import subprocess
import sys
from pathlib import Path
from typing import Iterable
from unittest import mock

import pytest

import appimage.private.tool.mkappimage as mkappimage


def test_deps() -> None:
    cmd = [os.fspath(mkappimage.APPIMAGE_RUNTIME), "--appimage-version"]
    output = subprocess.run(cmd, check=True, text=True, stderr=subprocess.PIPE).stderr
    assert output.startswith("AppImage runtime version")

    cmd = [os.fspath(mkappimage.MKSQUASHFS), "-version"]
    output = subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE).stdout
    assert output.startswith("mksquashfs version")


def fake_make_squashfs(params: mkappimage.AppDirParams, mksquashfs_params: Iterable[str], output_path: str) -> None:
    Path(output_path).write_bytes(b"fake squashfs")


@mock.patch("appimage.private.tool.mkappimage.make_squashfs", fake_make_squashfs)
def test_make_appimage() -> None:
    mkappimage.make_appimage(mkappimage.AppDirParams("", "", "", ""), [], Path("fake.appimage"))
    appimage = Path("fake.appimage").read_bytes()
    assert appimage.startswith(mkappimage.APPIMAGE_RUNTIME.read_bytes())
    assert appimage.endswith(b"fake squashfs")


if __name__ == "__main__":
    sys.exit(pytest.main(["-v", __file__]))
