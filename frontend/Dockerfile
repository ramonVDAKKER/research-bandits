FROM python:3.13-slim

# Install uv and curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Set working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml ./

# Install dependencies
RUN uv pip install --system -r pyproject.toml

# Copy source code and entrypoint
COPY src/ ./src/
COPY entrypoint.sh ./

RUN chmod +x /app/entrypoint.sh

# Set Python path
ENV PYTHONPATH=/app/src

EXPOSE 8000
HEALTHCHECK CMD curl --fail http://localhost:8000/_stcore/health

ENTRYPOINT ["/app/entrypoint.sh"]
