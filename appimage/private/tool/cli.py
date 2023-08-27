"""CLI to prepare and build AppImages."""


import argparse
from pathlib import Path
from typing import Optional, Sequence

from appimage.private.tool.mkappimage import AppDirParams, make_appimage


def parse_args(args: Optional[Sequence[str]] = None) -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Prepare and build AppImages.")
    parser.add_argument(
        "--manifest",
        required=True,
        type=Path,
        help="Path to manifest json with file and link definitions, e.g. 'bazel-bin/tests/appimage_py-manifest.json'",
    )
    parser.add_argument(
        "--envfile",
        required=True,
        type=Path,
        help="Path to sourcable envfile with runtime environment definition, e.g. 'bazel-bin/tests/appimage_py-env.sh'",
    )
    parser.add_argument(
        "--workdir",
        required=True,
        type=Path,
        help="Path to working dir, e.g. 'AppDir/tests/test_py.runfiles/rules_appimage'",
    )
    parser.add_argument(
        "--entrypoint",
        required=True,
        type=Path,
        help="Path to entrypoint, e.g. 'AppDir/tests/test_py'",
    )
    parser.add_argument(
        "--icon",
        required=True,
        type=Path,
        help="Icon to use in the AppImage, e.g. 'external/AppImageKit/resources/appimagetool.png'",
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
        help="",
    )
    parser.add_argument("output", type=Path, help="Where to place output AppImage")
    return parser.parse_args(args)


def cli(args: Optional[Sequence[str]] = None) -> None:
    """CLI entrypoint for mkappimage."""
    parsed_args = parse_args(args)
    appdir_params = AppDirParams(
        parsed_args.manifest,
        parsed_args.envfile,
        parsed_args.workdir,
        parsed_args.entrypoint,
        parsed_args.icon,
        parsed_args.runtime
    )
    make_appimage(appdir_params, parsed_args.mksquashfs_arg or [], parsed_args.output)


if __name__ == "__main__":
    cli()
