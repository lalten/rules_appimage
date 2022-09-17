"""Unit tests for tooling to prepare and build AppImages."""

import os
import subprocess
import sys

import click.testing
import pytest
import rules_appimage.appimage.private.tool.tool as tool


def test_appimagetool() -> None:
    cmd = [os.fspath(tool.APPIMAGE_RUNTIME), "--appimage-version"]
    output = subprocess.run(cmd, check=True, text=True, stderr=subprocess.PIPE).stderr

    assert output.splitlines()[-1].startswith("Version: ")


def test_cli() -> None:
    """Test the tool init."""
    cr = click.testing.CliRunner()
    resp = cr.invoke(tool.cli, ["--help"], catch_exceptions=False)
    assert resp.exit_code == os.EX_OK


if __name__ == "__main__":
    sys.exit(pytest.main(["-v", __file__]))
