"""CLI tool for generating synthetic data as parquet files."""

from datetime import datetime
from pathlib import Path

import click
import numpy as np
import pandas as pd


@click.command()
@click.option("--rows", default=1000, help="Number of rows to generate", type=int)
@click.option("--cols", default=10, help="Number of columns to generate", type=int)
@click.option(
    "--filename", default=None, help="Output filename (without .parquet extension)"
)
@click.option("--storage-path", default="/data", help="Storage directory path")
@click.option("--overwrite", is_flag=True, help="Overwrite existing files")
def generate(
    rows: int, cols: int, filename: str | None, storage_path: str, overwrite: bool
) -> None:
    """Generate synthetic numeric data and save as parquet file."""
    storage_dir = Path(storage_path)
    storage_dir.mkdir(parents=True, exist_ok=True)

    # Generate filename
    if filename:
        output_filename = f"{filename}.parquet"
    else:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_filename = f"data_{timestamp}.parquet"

    file_path = storage_dir / output_filename

    # Check if file exists
    if file_path.exists() and not overwrite:
        click.echo(f"Error: File {output_filename} already exists", err=True)
        raise SystemExit(1)

    click.echo(f"Generating {rows} rows × {cols} columns...")

    # Generate random numeric data
    data = np.random.randn(rows, cols)

    # Create DataFrame
    columns = [f"col_{i}" for i in range(cols)]
    df = pd.DataFrame(data, columns=columns)

    # Save as parquet
    click.echo(f"Writing to {file_path}...")
    df.to_parquet(file_path, engine="pyarrow", compression="snappy", index=False)

    file_size_mb = file_path.stat().st_size / (1024 * 1024)
    click.echo(f"Success! Generated {output_filename} ({file_size_mb:.2f} MB)")


if __name__ == "__main__":
    generate()
