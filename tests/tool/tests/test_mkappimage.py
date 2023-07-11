"""Unit tests for library to prepare and build AppImages."""

import os
import subprocess
import sys
from pathlib import Path
from typing import Iterable
from unittest import mock

import pytest

from appimage.private.tool import mkappimage


def test_deps() -> None:
    """Test that the runtime and mksquashfs can be executed."""
    cmd = [os.fspath(mkappimage.APPIMAGE_RUNTIME), "--appimage-version"]
    output = subprocess.run(cmd, check=True, text=True, stderr=subprocess.PIPE).stderr
    assert output.startswith("AppImage runtime version")

    cmd = [os.fspath(mkappimage.MKSQUASHFS), "-version"]
    output = subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE).stdout
    assert output.startswith("mksquashfs version")


def fake_make_squashfs(_params: mkappimage.AppDirParams, _mksquashfs_params: Iterable[str], output_path: str) -> None:
    """Fake the make_squashfs function."""
    Path(output_path).write_bytes(b"fake squashfs")


@mock.patch("appimage.private.tool.mkappimage.make_squashfs", fake_make_squashfs)
def test_make_appimage() -> None:
    """Test that the AppImage is created by concatenating the runtime and the squashfs."""
    params = mkappimage.AppDirParams(Path(), Path(), Path(), Path(), Path())
    mkappimage.make_appimage(params, [], Path("fake.appimage"))
    appimage = Path("fake.appimage").read_bytes()
    assert appimage.startswith(mkappimage.APPIMAGE_RUNTIME.read_bytes())
    assert appimage.endswith(b"fake squashfs")


if __name__ == "__main__":
    sys.exit(pytest.main(["-v", __file__]))
