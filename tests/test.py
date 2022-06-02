from pathlib import Path

import click

DATA_DEP = Path("tests/data.txt")
DIR_DEP = Path("tests/dir/file_in_dir.txt")


def test_datadep() -> None:
    assert DATA_DEP.is_file(), f"{DATA_DEP} does not exist"
    assert (s := DATA_DEP.stat().st_size) == 591, f"{DATA_DEP} has wrong size {s}"
    assert DIR_DEP.is_file(), f"{DIR_DEP} does not exist"


@click.command()
@click.option("--name", default="world")
def greeter(name: str) -> None:
    """A simple greeter."""
    click.echo(f"Hello, {name}!")


if __name__ == "__main__":
    test_datadep()
    greeter()
