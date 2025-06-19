"""Test that using rules_pycross does not produce invalid symlinks."""

from pathlib import Path


def test_symlinks() -> None:
    """Test that there are not broken symlinks in `..`."""
    for link in filter(Path.is_symlink, Path.cwd().parent.glob("**/*")):
        target = link.readlink()
        if not target.is_absolute():
            target = link.parent / target
        assert target.exists(), f"Broken link: {link} -> {target}"

    # Now do an actual import
    import humanize  # noqa: PLC0415 (`import` should be at the top-level of a file)

    assert humanize


if __name__ == "__main__":
    test_symlinks()
