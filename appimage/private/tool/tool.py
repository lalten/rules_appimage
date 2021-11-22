"""Tooling to prepare and build AppImages."""

import os
import shutil
import subprocess
import sys
import tempfile
import textwrap
from pathlib import Path
from typing import Iterable, Optional, Tuple

import click
from rules_python.python.runfiles import runfiles

APPIMAGE_TOOL = Path(runfiles.Create().Rlocation("rules_appimage/appimage/private/tool/appimagetool.bin"))


def _make_runfiles_entrypoint(apprun_path: Path, ExeName: str, WorkspaceName: str, app_path: str) -> None:
    """"""
    apprun_path.write_text(
        textwrap.dedent(
            f"""\
            #!/bin/sh
            set -eu
            HERE="$(dirname $0)"
            WD="${{HERE}}/{ExeName}.runfiles/{WorkspaceName}"
            cd "${{WD}}"
            exec "${{WD}}/{app_path}" "$@"
            """
        )
    )
    apprun_path.chmod(0o751)


def _make_desktop_file(desktopfile: Path) -> None:
    """"""
    desktopfile.write_text(
        textwrap.dedent(
            """\
            [Desktop Entry]
            Type=Application
            Name=AppRun
            Exec=AppRun
            Icon=AppRun
            Categories=Development;
            Terminal=true
            """
        )
    )


def _steal_runfiles(appdir: Path, runfiles_manifest: Path) -> None:
    """"""
    runfiles_dir = runfiles_manifest.resolve().parent
    shutil.copytree(src=runfiles_dir, dst=appdir / runfiles_dir.name, symlinks=False)


def make_appimage(
    app: Path,
    app_path: str,
    runfiles_manifest: Optional[Path],
    icon: Path,
    workspace_name: str,
    extra_args: Iterable[str],
    output_file: Path,
    quiet: bool,
) -> int:
    """Make an AppImage.

    See cli() for args.

    Returns:
        appimagetool return code
    """
    with tempfile.TemporaryDirectory(suffix=".AppDir") as appdir_name:
        appdir = Path(appdir_name)
        apprun_path = appdir / "AppRun"
        if runfiles_manifest:
            _make_runfiles_entrypoint(apprun_path, app.name, workspace_name, app_path)
            _steal_runfiles(appdir, runfiles_manifest)
        else:
            shutil.copy(src=app, dst=apprun_path, follow_symlinks=True)
        _make_desktop_file(apprun_path.with_suffix(".desktop"))
        shutil.copy(src=icon, dst=appdir / f"AppRun{icon.suffix}", follow_symlinks=True)

        cmd = [
            os.fspath(APPIMAGE_TOOL),
            *extra_args,
            os.fspath(appdir),
            os.fspath(output_file),
        ]
        proc = subprocess.run(cmd, check=False, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if not quiet or proc.returncode:
            print(proc.stdout)
        return proc.returncode


@click.command()
@click.option(
    "--app",
    required=True,
    type=click.Path(exists=True, path_type=Path),
    help="Path to binary that becomes the AppImage's entrypoint, e.g. 'bazel-out/k8-fastbuild/bin/tests/test_py'",
)
@click.option(
    "--app_path",
    required=True,
    help="App's path in workspace, e.g. 'tests/test_py'",
)
@click.option(
    "--runfiles_manifest",
    required=False,
    type=click.Path(exists=True, path_type=Path),
    help="Path to app's runfiles manifest file, e.g. 'bazel-out/k8-fastbuild/bin/tests/test_py.runfiles/MANIFEST'",
)
@click.option("--icon", required=True, type=click.Path(exists=True, path_type=Path), help="Icon to use in the AppImage")
@click.option(
    "--workspace_name",
    required=True,
    help="Name of Bazel workspace, e.g. 'rules_appimage'",
)
@click.option(
    "--extra_arg",
    "extra_args",
    required=False,
    multiple=True,
    help="Any extra arg to pass to appimagetool, e.g. '--no-appstream'. Can be used multiple times.",
)
@click.option(
    "--quiet",
    is_flag=True,
    show_default=True,
    help="Don't print appimagetool output unless there is an error",
)
@click.argument(
    "output",
    type=click.Path(path_type=Path),
)
def cli(
    app: Path,
    app_path: str,
    runfiles_manifest: Optional[Path],
    icon: Path,
    workspace_name: str,
    extra_args: Tuple[str],
    quiet: bool,
    output: Path,
) -> None:
    """Tool for rules_appimage.

    Writes the built AppImage to OUTPUT.
    """
    sys.exit(make_appimage(app, app_path, runfiles_manifest, icon, workspace_name, extra_args, output, quiet))


if __name__ == "__main__":
    cli()
