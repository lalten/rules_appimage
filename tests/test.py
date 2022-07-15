import os
from pathlib import Path

import click


def test_datadep() -> None:
    data_dep = Path("tests/data.txt")
    assert data_dep.is_file(), f"{data_dep} does not exist"
    assert (s := data_dep.stat().st_size) == 591, f"{data_dep} has wrong size {s}"


def test_symlinks() -> None:
    link_to_undeclared_dep = Path("tests/dir/link_to_file_in_dir2")
    assert link_to_undeclared_dep.is_symlink()
    assert link_to_undeclared_dep.read_text().strip() == "content of file_in_dir2"

    link_to_link_to_undeclared_dep = Path("tests/dir/link_to_link_to_file_in_dir2")
    assert link_to_link_to_undeclared_dep.read_text().strip() == "content of file_in_dir2"
    assert link_to_link_to_undeclared_dep.is_symlink()

    link_to_declared_dep = Path("tests/dir/subdir/symlink_to_local_file")
    assert link_to_declared_dep.is_file()
    assert link_to_declared_dep.is_symlink()
    assert os.readlink(link_to_declared_dep) == "../local_file"

    abs_link = Path("tests/dir/link_to_bin_sh")
    assert abs_link.is_file()
    assert abs_link.is_symlink()
    assert os.readlink(abs_link) == "/bin/sh"

    invalid_link = Path("tests/dir/subdir/invalid_link")
    assert invalid_link.is_symlink()
    assert os.readlink(invalid_link) == "invalid/target"
    assert not invalid_link.is_file()

    dir_link = Path("tests/dir/subdir/dir_link")
    assert dir_link.is_symlink()
    assert os.readlink(dir_link) == "dir"
    assert dir_link.resolve().is_dir()


@click.command()
@click.option("--name", default="world")
def greeter(name: str) -> None:
    """A simple greeter."""
    click.echo(f"Hello, {name}!")


if __name__ == "__main__":
    test_datadep()
    test_symlinks()
    greeter()
