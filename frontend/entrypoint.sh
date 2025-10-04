#!/bin/sh
set -e
exec streamlit run "./src/frontend/landing_zone.py" --server.port=8000
