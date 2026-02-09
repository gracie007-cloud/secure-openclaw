FROM node:20-slim

WORKDIR /app

# Install Playwright system deps (for browser features)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY package*.json ./
RUN npm install --production

# Install provider CLIs
RUN curl -fsSL https://claude.ai/install.sh | bash
RUN curl -fsSL https://opencode.ai/install | bash

COPY . .

# Create workspace for memory
RUN mkdir -p /root/clawd/memory

# WhatsApp auth persists via volume
VOLUME ["/app/auth_whatsapp", "/root/clawd"]

EXPOSE 4096

CMD ["node", "gateway.js"]
