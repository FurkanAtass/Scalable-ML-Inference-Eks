FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

COPY pyproject.toml uv.lock ./

RUN apt update -y && uv sync

COPY . .

CMD ["./run.sh"]