"""Data management utilities for listing and generating data files."""

from datetime import datetime
from pathlib import Path

import docker
import pandas as pd


class DataManager:
    """Manages data files and batch job execution."""

    def __init__(
        self,
        storage_path: str = "/data",
        backend_image: str = "research-bandits-backend",
    ):
        """Initialize DataManager.

        Args:
            storage_path: Path to shared storage directory
            backend_image: Docker image name for backend batch job
        """
        self.storage_path = Path(storage_path)
        self.backend_image = backend_image
        self.storage_path.mkdir(parents=True, exist_ok=True)

    def list_files(self) -> list[dict[str, str | int | float]]:
        """List all parquet files in storage.

        Returns:
            List of dicts with file metadata (filename, size_mb, modified)
        """
        files: list[dict[str, str | int | float]] = []
        for file_path in self.storage_path.glob("*.parquet"):
            stat = file_path.stat()
            files.append(
                {
                    "filename": file_path.name,
                    "size_mb": round(stat.st_size / (1024 * 1024), 2),
                    "modified": datetime.fromtimestamp(stat.st_mtime).strftime(
                        "%Y-%m-%d %H:%M:%S"
                    ),
                }
            )
        return sorted(files, key=lambda x: str(x["modified"]), reverse=True)

    def generate_data(
        self, rows: int = 1000, cols: int = 10, filename: str | None = None
    ) -> dict[str, str]:
        """Trigger batch job to generate data.

        Args:
            rows: Number of rows to generate
            cols: Number of columns to generate
            filename: Optional custom filename (without extension)

        Returns:
            Dict with status and logs
        """
        client = docker.from_env()

        # Build command arguments
        cmd = [
            "--rows",
            str(rows),
            "--cols",
            str(cols),
            "--storage-path",
            "/data",
        ]

        if filename:
            cmd.extend(["--filename", filename])

        try:
            # Run container as batch job
            container = client.containers.run(
                self.backend_image,
                command=cmd,
                volumes={
                    "research-bandits_shared-data": {"bind": "/data", "mode": "rw"},
                },
                remove=True,
                detach=False,
            )

            logs = (
                container.decode("utf-8")
                if isinstance(container, bytes)
                else str(container)
            )

            return {"status": "success", "logs": logs}

        except docker.errors.ContainerError as e:
            return {
                "status": "error",
                "logs": f"Container failed: {e.stderr.decode('utf-8')}",
            }
        except Exception as e:
            return {"status": "error", "logs": f"Unexpected error: {str(e)}"}

    def load_data(self, filename: str) -> pd.DataFrame:
        """Load a parquet file into a DataFrame.

        Args:
            filename: Name of the parquet file

        Returns:
            DataFrame with the data
        """
        file_path = self.storage_path / filename
        return pd.read_parquet(file_path)

    def delete_file(self, filename: str) -> bool:
        """Delete a parquet file.

        Args:
            filename: Name of the file to delete

        Returns:
            True if deleted successfully
        """
        file_path = self.storage_path / filename
        if file_path.exists():
            file_path.unlink()
            return True
        return False
