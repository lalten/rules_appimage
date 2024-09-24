"""Unit tests for mkappdir module."""

import contextlib
import os
import sys
import tempfile
from collections.abc import Iterator
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


@pytest.mark.parametrize(
    ("path", "expected"),
    [
        ("/", ["/"]),
        (".", []),
        ("/a", ["/"]),
        ("./a", []),
        ("/dev/null", ["/", "/dev"]),
        ("/dev", ["/", "/dev"]),
        ("a", []),
        ("a/b", ["a"]),
        ("a/b/c", ["a", "a/b"]),
        ("a/b/c/d", ["a", "a/b", "a/b/c"]),
    ],
)
def test_get_all_parent_dirs(path: str, expected: list[str]) -> None:
    assert mkappdir.get_all_parent_dirs(Path(path)) == list(map(Path, expected))


@contextlib.contextmanager
def cd(path: Path | str) -> Iterator[None]:
    old = Path.cwd()
    os.chdir(path)
    try:
        yield
    finally:
        os.chdir(old)


def test_to_pseudofile_def_lines() -> None:
    mkdef = mkappdir.to_pseudofile_def_lines
    with tempfile.TemporaryDirectory() as tmp_dir, cd(tmp_dir):
        src = Path("dir/file")
        src.parent.mkdir(parents=True, exist_ok=True)
        src.touch(0o601)
        dangling = Path("dangling")
        dangling.symlink_to("../invalid")
        link = Path("link")
        link.symlink_to(src)

        assert mkdef(src, Path("a/b/c/d"), True) == {
            "a": "d 755 0 0",
            "a/b": "d 755 0 0",
            "a/b/c": "d 755 0 0",
            "a/b/c/d": "f 601 0 0 cat dir/file",
        }
        assert mkdef(src, Path("dst"), True) == {"dst": "f 601 0 0 cat dir/file"}
        perms = f"{dangling.lstat().st_mode & 0o777:o}"  # this differs on Linux and macOS
        assert mkdef(dangling, Path("dst"), True) == {"dst": f"s {perms} 0 0 ../invalid"}
        assert mkdef(dangling, Path("dst"), False) == {"dst": f"s {perms} 0 0 ../invalid"}
        assert mkdef(link, Path("dst"), True) == {"dst": "s 777 0 0 dir/file"}
        assert mkdef(link, Path("dst"), False) == {"dst": "f 777 0 0 cat link"}


if __name__ == "__main__":
    sys.exit(pytest.main([__file__]))
