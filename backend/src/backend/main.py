"""Backend API service for data generation."""

import os
from datetime import datetime
from pathlib import Path

import numpy as np
import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="Research Bandits Backend")

STORAGE_PATH = Path(os.getenv("STORAGE_PATH", "/data"))


class GenerateDataRequest(BaseModel):
    """Request model for data generation."""

    num_rows: int = Field(
        default=1000, ge=100, le=1_000_000, description="Number of rows to generate"
    )
    num_cols: int = Field(
        default=10, ge=1, le=100, description="Number of columns to generate"
    )
    filename: str | None = Field(
        default=None, description="Optional filename (without extension)"
    )


class GenerateDataResponse(BaseModel):
    """Response model for data generation."""

    status: str
    filename: str
    path: str
    rows: int
    cols: int


class DataFile(BaseModel):
    """Model representing a data file."""

    filename: str
    size_bytes: int
    modified: str


@app.get("/")
async def root() -> dict[str, str]:
    """Root endpoint."""
    return {"message": "Research Bandits Backend API", "status": "running"}


@app.get("/health")
async def health() -> dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy"}


@app.get("/data/list", response_model=list[DataFile])
async def list_data_files() -> list[DataFile]:
    """List all available parquet files in storage."""
    if not STORAGE_PATH.exists():
        STORAGE_PATH.mkdir(parents=True, exist_ok=True)
        return []

    files = []
    for file_path in STORAGE_PATH.glob("*.parquet"):
        stat = file_path.stat()
        files.append(
            DataFile(
                filename=file_path.name,
                size_bytes=stat.st_size,
                modified=datetime.fromtimestamp(stat.st_mtime).isoformat(),
            )
        )

    return sorted(files, key=lambda x: x.modified, reverse=True)


@app.post("/data/generate", response_model=GenerateDataResponse)
async def generate_data(request: GenerateDataRequest) -> GenerateDataResponse:
    """Generate synthetic numeric data and save as parquet file."""
    # Ensure storage directory exists
    STORAGE_PATH.mkdir(parents=True, exist_ok=True)

    # Generate filename
    if request.filename:
        filename = f"{request.filename}.parquet"
    else:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"data_{timestamp}.parquet"

    file_path = STORAGE_PATH / filename

    # Check if file already exists
    if file_path.exists():
        raise HTTPException(status_code=409, detail=f"File {filename} already exists")

    # Generate random numeric data
    data = np.random.randn(request.num_rows, request.num_cols)

    # Create DataFrame with column names
    columns = [f"col_{i}" for i in range(request.num_cols)]
    df = pd.DataFrame(data, columns=columns)

    # Save as parquet
    df.to_parquet(file_path, engine="pyarrow", compression="snappy", index=False)

    return GenerateDataResponse(
        status="success",
        filename=filename,
        path=str(file_path),
        rows=request.num_rows,
        cols=request.num_cols,
    )


@app.delete("/data/{filename}")
async def delete_data_file(filename: str) -> dict[str, str]:
    """Delete a specific parquet file."""
    if not filename.endswith(".parquet"):
        filename = f"{filename}.parquet"

    file_path = STORAGE_PATH / filename

    if not file_path.exists():
        raise HTTPException(status_code=404, detail=f"File {filename} not found")

    file_path.unlink()

    return {"status": "deleted", "filename": filename}
