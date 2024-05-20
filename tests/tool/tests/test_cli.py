"""Unit tests for tooling to prepare and build AppImages."""

import argparse
import sys
from pathlib import Path

import pytest

from appimage.private.tool import cli


def test_cli() -> None:
    """Test the tool init."""
    args = cli.parse_args(
        [
            "--manifest",
            "manifest.json",
            "--apprun",
            "AppRun.sh",
            "--runtime",
            "runtime",
            "--icon",
            "icon",
            "--mksquashfs_arg=-mem",
            "--mksquashfs_arg=500M",
            "output",
        ],
    )
    assert args == argparse.Namespace(
        manifest=Path("manifest.json"),
        apprun=Path("AppRun.sh"),
        runtime=Path("runtime"),
        icon=Path("icon"),
        mksquashfs_arg=["-mem", "500M"],
        output=Path("output"),
    )


if __name__ == "__main__":
    sys.exit(pytest.main(["-v", __file__]))
