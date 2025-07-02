#! /bin/bash

if [ "$1" == "dev" ]; then
    uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000
else
    uv run uvicorn main:app --host 0.0.0.0 --port 8000
fi