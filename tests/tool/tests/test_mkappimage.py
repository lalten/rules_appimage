"""Unit tests for library to prepare and build AppImages."""

import os
import subprocess
import sys
from pathlib import Path
from typing import Iterable
from unittest import mock

import pytest

from appimage.private.tool import mkappimage


# NOTE: mypy warns about `untyped decorator`. Since this is a test, just ignore typing on this line
@pytest.mark.skipif(sys.platform.startswith("linux") is False, reason="AppImage can only run on Linux")  # type: ignore
def test_appimage_deps() -> None:
    """Test that the runtime can be executed on Linux."""
    runtime_path = mkappimage._get_path_or_raise("rules_appimage/tests/tool/tests/appimage_runtime_native")
    cmd = [os.fspath(runtime_path), "--appimage-version"]
    output = subprocess.run(cmd, check=True, text=True, stderr=subprocess.PIPE).stderr
    assert output.startswith("AppImage runtime version")


def test_mksquashfs_deps() -> None:
    """Test that mksquashfs can be executed."""
    cmd = [os.fspath(mkappimage.MKSQUASHFS), "-version"]
    output = subprocess.run(cmd, check=True, text=True, stdout=subprocess.PIPE).stdout
    assert output.startswith("mksquashfs version")


def fake_make_squashfs(_params: mkappimage.AppDirParams, _mksquashfs_params: Iterable[str], output_path: str) -> None:
    """Fake the make_squashfs function."""
    Path(output_path).write_bytes(b"fake squashfs")


@mock.patch("appimage.private.tool.mkappimage.make_squashfs", fake_make_squashfs)
def test_make_appimage_x86_64() -> None:
    """Test that the AppImage is created by concatenating the x86_64 runtime and the squashfs."""
    runtime_path = mkappimage._get_path_or_raise("rules_appimage/tests/tool/tests/appimage_runtime_x86_64")
    params = mkappimage.AppDirParams(Path(), Path(), Path(), Path(), Path(), Path(runtime_path))
    mkappimage.make_appimage(params, [], Path("fake.appimage"))
    appimage = Path("fake.appimage").read_bytes()
    assert appimage.startswith(runtime_path.read_bytes())
    assert appimage.endswith(b"fake squashfs")


@mock.patch("appimage.private.tool.mkappimage.make_squashfs", fake_make_squashfs)
def test_make_appimage_native() -> None:
    """Test that the AppImage is created by concatenating the native runtime and the squashfs."""
    runtime_path = mkappimage._get_path_or_raise("rules_appimage/tests/tool/tests/appimage_runtime_native")
    params = mkappimage.AppDirParams(Path(), Path(), Path(), Path(), Path(), Path(runtime_path))
    mkappimage.make_appimage(params, [], Path("fake.appimage"))
    appimage = Path("fake.appimage").read_bytes()
    assert appimage.startswith(runtime_path.read_bytes())
    assert appimage.endswith(b"fake squashfs")


if __name__ == "__main__":
    sys.exit(pytest.main(["-v", __file__]))
