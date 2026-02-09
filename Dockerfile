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

# Install Claude Code CLI via npm (avoids OOM from native installer)
RUN npm install -g @anthropic-ai/claude-code

# Install Opencode CLI
RUN curl -fsSL https://opencode.ai/install | bash

# Add CLI binary locations to PATH
ENV PATH="/root/.opencode/bin:/root/.local/bin:${PATH}"

COPY . .

# Create workspace for memory
RUN mkdir -p /root/secure-openclaw/memory

# Pre-accept Claude Code TOS for headless/Docker operation
ENV BROWSER_HEADLESS=true
RUN mkdir -p /root/.claude && \
    echo '{}' > /root/.claude/statsig_metadata.json && \
    echo '{"hasCompletedOnboarding":true}' > /root/.claude/settings.json

EXPOSE 4096

CMD ["node", "gateway.js"]
