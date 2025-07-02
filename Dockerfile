FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

COPY pyproject.toml uv.lock ./

RUN uv sync && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY . .

CMD ["./run.sh"]