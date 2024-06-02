"""CLI to prepare and build AppImages."""

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Sequence

from appimage.private.tool.mkappimage import AppDirParams, make_appimage


def parse_args(args: Sequence[str] | None = None) -> argparse.Namespace:
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
        "--mksquashfs_arg",
        required=False,
        action="append",
        help="Extra arguments for mksquashfs, e.g. '-mem'. Can be used multiple times.",
    )
    parser.add_argument(
        "--runtime",
        required=True,
        type=Path,
        help="AppImage runtime binary, needs to match target architecture",
    )
    parser.add_argument("output", type=Path, help="Where to place output AppImage")
    return parser.parse_args(args)


def cli(args: Sequence[str] | None = None) -> None:
    """CLI entrypoint for mkappimage."""
    parsed_args = parse_args(args)
    appdir_params = AppDirParams(
        parsed_args.manifest,
        parsed_args.apprun,
        parsed_args.runtime,
    )
    make_appimage(appdir_params, parsed_args.mksquashfs_arg or [], parsed_args.output)


if __name__ == "__main__":
    cli()
