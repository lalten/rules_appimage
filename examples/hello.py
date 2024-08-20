"""Example Python application."""

from pathlib import Path

import click

DATA_FILE = Path("resources/data.txt")


@click.command()
def main() -> None:
    """Print "Hello, world!" to the console."""
    data = DATA_FILE.read_text().strip()
    click.echo(data)


if __name__ == "__main__":
    main()
