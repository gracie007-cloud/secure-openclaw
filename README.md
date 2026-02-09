# Secure OpenClaw

A personal AI assistant that runs on your messaging platforms. Send a message on WhatsApp, Telegram, Signal, or iMessage and get responses from Claude with full tool access, persistent memory, scheduled reminders, browser automation, and integrations with 500+ apps.

---

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Deploying Remotely](#deploying-remotely)
- [Providers](#providers)
- [Configuration](#configuration)
- [Messaging Platforms](#messaging-platforms)
- [Tool Approvals](#tool-approvals)
- [Browser Control](#browser-control)
- [Memory System](#memory-system)
- [Scheduling and Reminders](#scheduling-and-reminders)
- [App Integrations](#app-integrations)
- [Commands](#commands)
- [Troubleshooting](#troubleshooting)
- [Directory Structure](#directory-structure)

---

## Requirements

- Node.js 18+
- macOS, Linux, or Windows
- Anthropic API key (`ANTHROPIC_API_KEY`)
- Composio API key (`COMPOSIO_API_KEY`)
- **Claude Code** — required if using the Claude provider
- **Opencode** — required if using the Opencode provider

Platform-specific:
- WhatsApp: a phone with WhatsApp installed
- Telegram: a bot token from @BotFather
- Signal: signal-cli installed and registered
- iMessage: macOS only, requires the `imsg` CLI tool

---

## Installation

### 1. Clone and install dependencies

```bash
git clone <repo-url> secure-openclaw
cd secure-openclaw
npm install
```

### 2. Install a provider

You need at least one AI provider installed on the machine.

**Claude Code** (for the Claude provider):

```bash
npm install -g @anthropic-ai/claude-code
```

**Opencode** (for the Opencode provider):

```bash
curl -fsSL https://opencode.ai/install | bash
```

You can install both. The CLI lets you switch between them.

After installing Claude Code, authenticate it locally:

```bash
claude
# Follow the OAuth prompts to log in with your Anthropic account
```

On remote/Docker deployments, authentication is handled by the `ANTHROPIC_API_KEY` environment variable instead — no interactive login needed.

### 3. API keys

**Anthropic** — get your key from https://console.anthropic.com/

```bash
export ANTHROPIC_API_KEY=sk-ant-...
```

**Composio** — provides 500+ app integrations (Gmail, Slack, GitHub, etc.)

```bash
curl -fsSL https://composio.dev/install | bash
composio login
composio whoami   # shows your API key
export COMPOSIO_API_KEY=your-key
```

Add all exports to your shell profile (`~/.zshrc` or `~/.bashrc`) to make them permanent.

---

## Quick Start

```bash
node cli.js
```

This opens the interactive menu:

```
1) Terminal chat      — talk to the assistant in your terminal
2) Start gateway      — run the messaging gateway
3) Setup adapters     — configure WhatsApp, Telegram, etc.
4) Configure browser  — set up browser automation
5) Show current config
6) Test connection
7) Change provider
8) Exit
```

Or run directly:

```bash
node cli.js chat     # terminal chat
node cli.js start    # start the gateway
```

---

## Deploying Remotely

The gateway can run on a remote server. Terminal chat is local only.

The remote machine needs the same prerequisites: Node.js 18+, Claude Code or Opencode installed, and the relevant API keys.

### Railway (Easiest)

Railway auto-detects the included `Dockerfile`, builds, and runs.

1. Push your repo to GitHub
2. Go to [railway.app](https://railway.app), sign in with GitHub
3. New Project > Deploy from GitHub repo
4. Add environment variables:
   - `ANTHROPIC_API_KEY`
   - `COMPOSIO_API_KEY`
   - `TELEGRAM_BOT_TOKEN` (if using Telegram)
   - `WHATSAPP_ALLOWED_DMS`, `WHATSAPP_ALLOWED_GROUPS`, etc.
5. Add a persistent volume mounted at `/app/auth_whatsapp` (for WhatsApp session)
6. Add a persistent volume mounted at `/root/clawd` (for memory)
7. Deploy

WhatsApp requires QR code auth on first boot. Check Railway's log panel for the QR code, scan it from your phone. The session persists via the volume.

Telegram works immediately — no QR needed, just the bot token.

Railway free tier: 500 hours/month. After that, roughly $5/month.

The Dockerfile installs both Claude Code and Opencode, so either provider works out of the box. No interactive CLI login is needed — Claude Code authenticates via the `ANTHROPIC_API_KEY` environment variable, and Opencode authenticates via the model provider's API key (e.g. `OPENAI_API_KEY`).

### Docker

```bash
docker build -t openclaw .
docker run -d \
  --name openclaw \
  -e ANTHROPIC_API_KEY=sk-ant-... \
  -e COMPOSIO_API_KEY=... \
  -e TELEGRAM_BOT_TOKEN=... \
  -v openclaw-wa:/app/auth_whatsapp \
  -v openclaw-memory:/root/clawd \
  openclaw
```

### VPS (Manual)

Any Linux VPS (Hetzner, DigitalOcean, AWS EC2):

```bash
ssh your-server
git clone <repo-url> secure-openclaw
cd secure-openclaw
npm install

# Install provider
npm install -g @anthropic-ai/claude-code

# Set env vars
export ANTHROPIC_API_KEY=sk-ant-...
export COMPOSIO_API_KEY=...

# Run with a process manager
npm install -g pm2
pm2 start gateway.js --name openclaw
pm2 save
pm2 startup
```

### What Runs Where

| Feature | Local | Remote |
|---------|-------|--------|
| Terminal chat | Yes | No |
| Gateway (WhatsApp, Telegram, etc.) | Yes | Yes |
| Browser automation | Yes | Headless only |
| Memory | Yes | Yes (needs volume) |
| Cron/reminders | Yes | Yes |
| Composio integrations | Yes | Yes |

---

## Providers

Secure OpenClaw supports two AI providers:

**Claude Agent SDK** — Anthropic's SDK. Uses your `ANTHROPIC_API_KEY`. Requires Claude Code installed. Models: Opus 4.6, Sonnet 4.5, Haiku 4.5.

**Opencode** — open-source alternative. Requires Opencode installed. Runs a local server or connects to an existing one. Models: GPT-5 Nano, Big Pickle, GLM-4.7, Grok Code, MiniMax M2.1.

Switch providers from the CLI menu (option 7) or in `config.js`:

```javascript
agent: {
  provider: 'claude',    // or 'opencode'
}
```

When using Opencode, the provider auto-detects whether a server is already running on the configured port. If one exists, it connects. If not, it starts one.

Use `/model` during terminal chat to switch models within the active provider.

---

## Configuration

All settings live in `config.js`. Edit directly or use the setup wizard.

```javascript
{
  agentId: 'clawd',

  whatsapp: { enabled: true, allowedDMs: [...], allowedGroups: [...] },
  telegram: { enabled: false, token: '', ... },
  signal:   { enabled: false, phoneNumber: '', ... },
  imessage: { enabled: false, ... },

  agent: {
    workspace: '~/clawd',
    maxTurns: 100,
    allowedTools: ['Read', 'Write', 'Edit', 'Bash', 'Glob', 'Grep'],
    provider: 'claude',
    opencode: {
      model: 'opencode/gpt-5-nano',
      hostname: '127.0.0.1',
      port: 4096
    }
  },

  browser: {
    enabled: true,
    mode: 'clawd',
    ...
  }
}
```

### Security

Each platform has an allowlist for DMs and groups. Set to `['*']` to allow all, or list specific IDs.

```javascript
whatsapp: {
  allowedDMs: ['+1234567890'],     // only this number can DM
  allowedGroups: ['*'],            // all groups allowed
  respondToMentionsOnly: true      // in groups, only respond when @mentioned
}
```

Messages from unrecognized senders are silently dropped.

---

## Messaging Platforms

### WhatsApp

Uses QR code authentication. No bot token needed.

1. Enable in config or run the setup wizard
2. Start the gateway
3. Scan the QR code that appears in your terminal (WhatsApp > Settings > Linked Devices)
4. Session saves to `auth_whatsapp/` — you only scan once

### Telegram

1. Message @BotFather on Telegram, send `/newbot`, copy the token
2. Add the token to config:

```javascript
telegram: {
  enabled: true,
  token: 'YOUR_BOT_TOKEN',
  allowedDMs: ['*'],
}
```

3. Start the gateway, then message your bot

### Signal

Requires signal-cli to be installed and registered.

```bash
signal-cli -u +1234567890 register
signal-cli -u +1234567890 verify CODE
```

Then configure:

```javascript
signal: {
  enabled: true,
  phoneNumber: '+1234567890',
  signalCliPath: 'signal-cli',
}
```

### iMessage

macOS only. Requires the `imsg` CLI tool.

```bash
brew install steipete/formulae/imsg
```

Enable in config. Make sure Messages.app is open and signed in.

---

## Tool Approvals

The gateway runs with permission mode `default`, which means the assistant asks for approval before using certain tools. When a tool needs approval:

**In terminal chat:** the spinner pauses, the tool name and details are printed, and you type `y` or `n` to approve or deny.

**On messaging platforms:** the assistant sends you a message like "Claude wants to use Bash. Reply Y to allow, N to deny." Your next reply resolves the approval.

If the assistant uses `AskUserQuestion` to ask clarifying questions, these are formatted as numbered options. Reply with a number or type your answer.

Approvals time out after 2 minutes with no response.

---

## Browser Control

Two modes for browser automation.

### Clawd Mode (Isolated Browser)

Launches a dedicated Chromium instance with its own profile. Clean slate, no existing logins.

Setup: run the CLI, select "Configure browser", choose "clawd". Install Playwright Chromium when prompted.

### Chrome Mode (Your Existing Browser)

Connects to your running Chrome via CDP. Keeps your logged-in sessions.

Start Chrome with remote debugging:

```bash
# macOS
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222

# Linux
google-chrome --remote-debugging-port=9222
```

Then start the gateway. It connects to your Chrome.

Security note: this gives the assistant access to all your open tabs and sessions.

### Available Browser Tools

`browser_navigate`, `browser_snapshot`, `browser_screenshot`, `browser_click`, `browser_type`, `browser_press`, `browser_tabs`, `browser_switch_tab`, `browser_new_tab`, `browser_close_tab`, `browser_back`, `browser_forward`, `browser_reload`

The assistant prefers Composio tools for app tasks (email, Slack, GitHub). Browser tools are only used when you explicitly ask to browse a website.

---

## Memory System

Persistent memory stored at `~/clawd/`.

```
~/clawd/
  MEMORY.md              — long-term: preferences, people, decisions
  memory/
    YYYY-MM-DD.md        — daily logs
    [topic].md           — topic-specific notes
```

Memory is loaded at the start of each conversation. The assistant writes to memory when you ask it to remember something. It does not proactively write memory on every message.

Use the `/memory` command in chat to view or search memories.

---

## Scheduling and Reminders

The assistant can schedule messages using cron tools.

- "Remind me in 30 minutes to check the oven" — one-time delay
- "Every day at 9am, send me a standup reminder" — cron expression `0 9 * * *`
- "Every weekday at 8am" — cron expression `0 8 * * 1-5`

Jobs persist in `~/.clawd/cron-jobs.json` and execute while the gateway is running.

---

## App Integrations

Composio provides access to 500+ apps:

- Gmail, Google Calendar, Google Sheets, Google Drive
- Slack, Discord
- GitHub, GitLab, Jira, Linear
- Notion, Trello, Asana
- Salesforce, HubSpot
- Twitter/X, LinkedIn
- And many more

Just ask: "Send an email to john@example.com", "Create a GitHub issue for the login bug", "Add an event to my calendar for tomorrow at 3pm".

On first use of an app, Composio provides an auth link. Click it to authorize, then the assistant can use that app going forward.

---

## Commands

### CLI

```bash
node cli.js              # interactive menu
node cli.js chat         # terminal chat
node cli.js start        # start gateway
node cli.js setup        # setup wizard
node cli.js config       # show config
node cli.js help         # help
```

### In Chat

| Command | Description |
|---------|-------------|
| `/new`, `/reset` | Start a fresh conversation |
| `/status` | Show session info |
| `/memory` | Show memory summary |
| `/memory list` | List all memory files |
| `/memory search <query>` | Search memories |
| `/model` | Switch model (terminal only) |
| `/queue` | Message queue status |
| `/stop` | Stop current operation |
| `/help` | Show commands |

---

## Troubleshooting

**"ANTHROPIC_API_KEY not set"** — export the key in your shell or `.env` file.

**"claude: command not found"** — Claude Code is not installed. Run `curl -fsSL https://claude.ai/install.sh | bash`.

**"opencode: command not found"** — Opencode is not installed. Run `curl -fsSL https://opencode.ai/install | bash`.

**Composio not working** — make sure `COMPOSIO_API_KEY` is set. Run `composio login` and `composio whoami` to get your key.

**WhatsApp QR not appearing** — delete `auth_whatsapp/` and restart.

**Browser not starting (clawd mode)** — run `npx playwright install chromium`.

**Browser not connecting (chrome mode)** — make sure Chrome is running with `--remote-debugging-port=9222` before starting the gateway.

**Telegram bot not responding** — verify the token, make sure you sent `/start` to your bot, check `enabled: true`.

**Signal not working** — verify signal-cli is installed, phone number is registered and includes country code.

**iMessage not working** — macOS only. Check that Messages.app is open, imsg is installed (`which imsg`), and accessibility permissions are granted.

**Opencode server failing** — if port 4096 is already in use from a previous run, kill the old process: `kill $(lsof -ti :4096)`. The provider auto-detects running servers, so usually this resolves itself.

**Memory not persisting on remote** — make sure you have a persistent volume mounted at `/root/clawd`.

---

## Directory Structure

```
secure-openclaw/
  config.js              configuration
  cli.js                 CLI entry point (menu, terminal chat)
  gateway.js             gateway process (messaging platforms)
  Dockerfile             container build for remote deployment
  adapters/
    base.js              base adapter class
    whatsapp.js          WhatsApp via Baileys
    telegram.js          Telegram via node-telegram-bot-api
    signal.js            Signal via signal-cli
    imessage.js          iMessage via imsg (macOS)
  agent/
    claude-agent.js      agent with memory, cron, system prompt
    runner.js            queue + run coordinator
  providers/
    base-provider.js     provider interface
    claude-provider.js   Claude Agent SDK provider
    opencode-provider.js Opencode provider
    index.js             provider registry
  browser/
    server.js            browser automation server
    mcp.js               browser MCP tools
  memory/
    manager.js           memory file management
  tools/
    cron.js              scheduling tools
    gateway.js           gateway MCP tools (send_message, etc.)
  commands/
    handler.js           slash command handlers
  sessions/
    manager.js           session tracking

~/clawd/                 workspace (created on first use)
  MEMORY.md              long-term memory
  memory/                daily logs and topic files
```

---

## License

MIT
