import os
from pathlib import Path

import click


def test_datadep() -> None:
    data_dep = Path("tests/data.txt")
    assert data_dep.is_file(), f"{data_dep} does not exist"
    assert (s := data_dep.stat().st_size) == 591, f"{data_dep} has wrong size {s}"


def test_symlinks() -> None:
    link_to_undeclared_dep = Path("tests/dir/file_in_dir.txt")
    assert link_to_undeclared_dep.is_file()
    assert not link_to_undeclared_dep.is_symlink()
    
    link_to_link_to_undeclared_dep = Path("tests/dir/symlink_to_file_in_dir")
    assert link_to_link_to_undeclared_dep.is_file()
    assert link_to_link_to_undeclared_dep.is_symlink()
    assert os.readlink(link_to_link_to_undeclared_dep) == "../dir/file_in_dir.txt"

    link_to_declared_dep = Path("tests/dir/subdir/symlink_to_local_file")
    assert link_to_declared_dep.is_file()
    assert link_to_declared_dep.is_symlink()
    assert os.readlink(link_to_declared_dep) == "../local_file"

    abs_link = Path("tests/dir/binsh")
    assert abs_link.is_file()
    assert abs_link.is_symlink()
    assert os.readlink(abs_link) == "/bin/sh"

    invalid_link = Path("tests/dir/subdir/invalid_link")
    assert invalid_link.is_symlink()
    assert os.readlink(invalid_link) == "invalid/target"
    assert not invalid_link.is_file()


@click.command()
@click.option("--name", default="world")
def greeter(name: str) -> None:
    """A simple greeter."""
    click.echo(f"Hello, {name}!")


if __name__ == "__main__":
    test_datadep()
    test_symlinks()
    greeter()
