FROM node:20-slim

WORKDIR /app

# System deps: curl for CLI installs, git for agent tools, ca-certificates for HTTPS
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install npm dependencies first (best cache layer)
COPY package*.json ./
RUN npm install --production

# Install provider CLIs
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && curl -fsSL https://opencode.ai/install | bash

# Add CLI binary locations to PATH
ENV PATH="/root/.claude/local/bin:/root/.opencode/bin:/root/.local/bin:${PATH}"

COPY . .

# Create workspace for memory (Railway volume mounts here)
RUN mkdir -p /root/clawd/memory

# Headless environment — no TTY, no display
ENV CI=true

EXPOSE 4096

CMD ["node", "gateway.js"]
