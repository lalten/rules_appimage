"""Unit tests for mkappdir module."""

import json
import os
import sys
import tarfile
import tempfile
from pathlib import Path

import pytest

from appimage.private import mkappdir


@pytest.mark.parametrize(
    ("target", "origin", "expected"),
    [
        ("/", "/", "."),
        ("/usr/bin", "/usr", "bin"),
        ("/usr/bin", "/", "usr/bin"),
        ("/a/b/c", "/a/b/d", "../c"),
        ("a/b/c/d", "a/b/d/e", "../../c/d"),
    ],
)
def test_relative_path(target: str, origin: str, expected: str) -> None:
    relative = mkappdir.relative_path(Path(target), Path(origin))
    assert relative == Path(expected)


def test_get_output_base() -> None:
    ob = mkappdir.get_output_base()
    assert __file__.startswith(ob)


@pytest.mark.parametrize(
    ("path", "expected"),
    [
        (Path(), False),
        (Path().resolve(), True),
        (Path(__file__), True),
        (Path("/"), False),
        (Path("bazel-out/stable-status.txt"), False),
        (Path("bazel-out/stable-status.txt").resolve(), True),
    ],
)
def test_is_inside_bazel_cache(path: Path, expected: bool) -> None:
    inside = mkappdir.is_inside_bazel_cache(path)
    assert inside == expected


@pytest.mark.parametrize("symlinks", [True, False])
def test_copy_file_or_dir(symlinks: bool) -> None:
    with tempfile.TemporaryDirectory(suffix=".src") as tmp_dir:
        src = Path(tmp_dir) / "src"
        src.mkdir()

        foo = src / "foo"
        foo.mkdir(mode=0o701)

        bar = foo / "bar"
        bar.write_text("bar")
        bar.chmod(0o456)
        os.utime(bar, (0, 200))
        os.utime(foo, (0, 100))

        dir = src / "dir"
        dir.mkdir()

        link = src / "baz/link"
        link.parent.mkdir()
        link.symlink_to("../foo/bar")

        dangling = src / "dangling"
        dangling.symlink_to("invalid")

        dst_link = Path(tmp_dir) / "dstfile/baz/link"
        dst_bar = Path(tmp_dir) / "dstfile/foo/bar"
        mkappdir.copy_file_or_dir(link, dst_link, preserve_symlinks=symlinks)
        mkappdir.copy_file_or_dir(bar, dst_bar, preserve_symlinks=symlinks)

        assert dst_link.exists()
        assert dst_link.is_symlink() is symlinks
        assert dst_link.read_text() == "bar"

        dst = Path(tmp_dir) / "dst_dir"
        mkappdir.copy_file_or_dir(src, dst, preserve_symlinks=symlinks)

        assert set(dst.rglob("*")) == {
            dst / "foo",
            dst / "foo/bar",
            dst / "dir",
            dst / "baz",
            dst / "baz/link",
            dst / "dangling",
        }

        foo = dst / "foo"
        assert foo.exists()
        assert foo.is_dir()
        assert oct(foo.stat().st_mode) == "0o40701"
        assert foo.stat().st_mtime == 100

        file = dst / "foo/bar"
        assert file.read_text() == "bar"
        assert oct(file.stat().st_mode) == "0o100456"
        assert file.stat().st_mtime == 200

        link = dst / "baz/link"
        assert link.exists()
        assert link.is_file()
        if symlinks:
            assert link.readlink() == Path("../foo/bar")
        else:
            assert not link.is_symlink()
        assert link.read_text() == "bar"

        dangling = dst / "dangling"
        assert dangling.is_symlink()
        assert not dangling.exists()


def test_populate_appdir() -> None:
    with (
        tempfile.NamedTemporaryFile(suffix=".json") as manifest_file,
        tempfile.TemporaryDirectory() as tmp_dir,
    ):
        manifest = Path(manifest_file.name)
        manifest.write_text(
            json.dumps(
                {
                    "empty_files": ["empty_file"],
                    "files": [{"src": __file__, "dst": "dir/b"}],
                    "symlinks": [{"linkname": "link/symlink", "target": "dir/b"}],
                    "tree_artifacts": [{"src": Path(__file__).parent.as_posix(), "dst": "tree"}],
                }
            )
        )
        appdir = Path(tmp_dir)
        mkappdir.populate_appdir(appdir, manifest)

        assert (appdir / "empty_file").read_text() == ""
        assert (appdir / "dir/b").read_text() == Path(__file__).read_text()
        assert (appdir / "link/symlink").is_symlink()
        assert (appdir / "tree" / Path(__file__).name).read_text() == Path(__file__).read_text()


def test_make_appdir() -> None:
    with (
        tempfile.NamedTemporaryFile(suffix=".json") as manifest,
        tempfile.NamedTemporaryFile(suffix=".AppRun") as apprun,
        tempfile.TemporaryDirectory() as tmpdir,
    ):
        Path(manifest.name).write_text(
            json.dumps(
                {
                    "empty_files": [],
                    "files": [],
                    "symlinks": [{"linkname": "link/symlink", "target": "AppRun"}],
                    "tree_artifacts": [],
                }
            )
        )
        Path(apprun.name).write_text("#!/bin/sh\n")
        output = Path(tmpdir) / "AppDir"
        assert not output.exists()

        mkappdir.make_appdir(Path(manifest.name), Path(apprun.name), output)

        assert set(output.rglob("*")) == {output / "link", output / "link/symlink", output / "AppRun"}
        assert not (output / "AppRun").is_symlink()
        assert (output / "link/symlink").readlink() == Path("../AppRun")
        assert (output / "link/symlink").read_text() == "#!/bin/sh\n"


if __name__ == "__main__":
    sys.exit(pytest.main([__file__]))
