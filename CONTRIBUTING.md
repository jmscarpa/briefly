# Contributing to briefly

Thanks for taking the time to improve **briefly**! This doc explains how to set up your environment, run the CLI locally, test changes, and open pull requests.

---

## Table of Contents

* [Requirements](#requirements)
* [Repository Setup](#repository-setup)
* [Project Structure](#project-structure)
* [Running the CLI Locally](#running-the-cli-locally)
* [Configuration](#configuration)
* [Development Workflow](#development-workflow)
* [Testing](#testing)
* [Code Style](#code-style)
* [Releasing](#releasing)
* [PR Guidelines](#pr-guidelines)

---

## Requirements

* **Node.js ≥ 18** (recommended to use [Volta](https://volta.sh) or nvm)
* **git**, **curl**, **jq**, **bash** (macOS/Linux by default; on Windows use WSL or Git Bash)
* Optional: **shellcheck** for static analysis of bash scripts

```bash
# macOS (Homebrew)
brew install volta jq shellcheck

# Debian/Ubuntu
sudo apt-get install -y jq shellcheck
```

---

## Repository Setup

```bash
git clone https://github.com/your-org/briefly.git
cd briefly
npm install   # not strictly required, but keeps npm metadata in sync
```

> We publish a single executable via npm that dispatches to `cmds/*.sh`.

---

## Project Structure

```
briefly/
├─ package.json
├─ README.md
├─ LICENSE
├─ cli.sh               # entrypoint (the 'briefly' command)
├─ lib/
│  └─ common.sh         # shared helpers + config loader
└─ cmds/
   ├─ setup.sh          # briefly setup (writes project-local .briefly)
   ├─ generate.sh       # briefly generate (writes briefly-summary.md)
   └─ publish.sh        # briefly publish (posts to Discord)
```

---

## Running the CLI Locally

### Option A: with `npm link` (global command)

```bash
chmod +x cli.sh cmds/*.sh
npm link          # exposes "briefly" on your PATH
briefly --help
```

### Option B: direct execution (no install)

```bash
./cli.sh --help
```

> Using Volta? No special steps needed. We resolve shims/symlinks in `cli.sh` so subcommands are found correctly.

---

## Configuration

All configuration is **project-local** via a `.briefly` file in your repository root. Create it via:

```bash
briefly setup
# or, explicitly:
briefly setup path/to/your/repo
```

Example `.briefly` (do **not** commit secrets):

```ini
OPENAI_API_KEY=sk-...
DISCORD_WEBHOOK=https://discord.com/api/webhooks/...
DEFAULT_MODEL=gpt-4o-mini
PROJECT_KIND=api
DEFAULT_ENV=staging
DEFAULT_APP_URL=https://staging.example.com
```

You can add a **`.briefly.example`** (no secrets) to help others.

---

## Development Workflow

1. Create a feature branch:

   ```bash
   git checkout -b feat/better-usage
   ```
2. Make changes in `cmds/*.sh`, `lib/common.sh`, or `cli.sh`.
3. Run local tests (see [Testing](#testing)).
4. Update `README.md` if behavior/flags changed.
5. Commit using a clear message (we suggest Conventional Commits):

   ```
   feat(generate): support --date and custom output name
   fix(publish): handle 200 and 204 from Discord webhook
   docs: add .briefly.example
   ```
6. Push and open a PR.

---

## Testing

### Quick sanity checks

```bash
# syntax checks (bash will print nothing if OK)
bash -n cli.sh lib/common.sh cmds/setup.sh cmds/generate.sh cmds/publish.sh

# static analysis (optional)
shellcheck cli.sh lib/common.sh cmds/*.sh || true
```

### Manual workflow

```bash
npm link
briefly setup                   # writes ./.briefly in the repo
briefly generate --date 2025-08-18
briefly publish --kind api --thread-id <THREAD_ID>
```

### Mock/Dry runs

For Discord payload debugging without sending:

```bash
# Example tweak (not committed): print payload and exit in publish.sh
# echo "$payload" | jq .; exit 0
```

---

## Code Style

* Bash: `set -euo pipefail`, quote variables, prefer `[[ ... ]]`.
* Keep scripts POSIX-friendly where reasonable; bash features are OK.
* Small, focused functions. Reuse helpers in `lib/common.sh`.
* Comments and docstrings in **English**.

---

## Releasing

1. Update version in `package.json` and `cli.sh` (VERSION).
2. Update `CHANGELOG` (optional) and `README` if needed.
3. Tag and publish:

   ```bash
   git commit -am "chore: release v0.x.y"
   git tag v0.x.y
   git push && git push --tags
   npm publish
   ```

---

## PR Guidelines

* One focused change per PR (avoid mixing refactors and features).
* Include context in the description (what/why), screenshots if relevant.
* Add/update docs when behavior changes.
* Be open to review comments and iterate quickly. 🙌
