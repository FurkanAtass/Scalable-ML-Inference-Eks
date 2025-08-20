FROM nvidia/cuda:12.8.1-base-ubuntu24.04

COPY pyproject.toml uv.lock ./

# Install Python and uv
RUN apt update && \
    apt install -y curl && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    export PATH="/root/.local/bin:$PATH" && \
    uv sync && \
    # Clean up apt cache and remove package lists to minimize final image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set environment variables to persist across container sessions
ENV PATH="/root/.local/bin:$PATH"

COPY . .

CMD ["./run.sh"]

