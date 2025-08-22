# Briefly

**briefly** is a simple CLI tool to generate and publish concise product changelogs from git commits.
It uses the OpenAI API to summarize commit logs into human-readable changelogs, and can publish them directly to Discord.

---

## ✨ Features

* Generate weekly product changelogs from git commit history.
* Summarize commits into clear, well-structured Markdown.
* Publish changelogs directly to a Discord channel (or thread) via webhook.
* Store API keys and defaults in a local `.briefly` config file inside each project.
* Works on macOS, Linux, and Windows (via Node.js / npm).

---

## 📦 Installation

```bash
npm install -g @jmscarpa/briefly
```

or use it without global install:

```bash
npx briefly <command>
```

Requirements:

* Node.js v18 or higher
* `git` and `jq` available in your system

---

## ⚙️ Setup

Run the setup command once in your project to store configuration (API key, webhook, defaults):

```bash
briefly setup
```

This will create a config file at:

* `<your-project>/.briefly`

The config file is a simple key=value format, for example:

```ini
OPENAI_API_KEY=sk-...
DISCORD_WEBHOOK=https://discord.com/api/webhooks/...
DEFAULT_MODEL=gpt-4o-mini
PROJECT_KIND=api
DEFAULT_ENV=staging
DEFAULT_APP_URL=https://staging.example.com
```

> 🔒 The file is created with restricted permissions (`chmod 600`) so only your user can read/write.

---

## 🚀 Usage

### Generate a changelog

```bash
briefly generate --date 2025-08-18
```

* Runs in the current git repository
* `--date`: optional; only include commits since this date (YYYY-MM-DD)
* `--out`: optional; output file (default: `briefly-summary.md`)

Example output saved to `briefly-summary.md`:

```markdown
# My Repo – Weekly Changelog

### Features
- Added new authentication flow
- Improved dashboard UI

### Fixes
- Fixed bug with user profile updates
```

---

### Publish a changelog to Discord

```bash
briefly publish briefly-summary.md --kind api
```

* `briefly-summary.md`: changelog file generated with `briefly generate`
* `--kind`: type of project (`api`, `frontend`, `backend`, etc.)
* `--thread-id`: optional; publish to an existing thread
* `--mention`: optional; mention a user or role (e.g. `<@&1234567890>`)

Example:

```bash
briefly publish briefly-summary.md --kind api --mention "<@&1386829090006503586>" --thread-id "123456789012345678"
```

---

## 🛠 Development

Clone this repo and link locally:

```bash
git clone https://github.com/your-user/briefly.git
cd briefly
npm link
```

Now you can run:

```bash
briefly setup
briefly generate
briefly publish briefly-summary.md --kind frontend
```

---

## 📄 License

MIT License © João Mateus Scarpa
