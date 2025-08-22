#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------------------------
# Common library for briefly CLI
#
# This file provides helper functions used by all commands:
#   - require_cmd: ensure required executables are available
#   - find_project_config: locate the .briefly config file for a repo
#   - load_project_config: load and export configuration variables
#   - utc_now: return current UTC timestamp in ISO-8601
#   - truncate_discord: safely truncate text for Discord embeds
#
# Notes:
#   - Config is always project-local (stored in ./ .briefly).
#   - Defaults are applied if some keys are missing in the file.
#   - Validation is deferred: generate requires OPENAI_API_KEY,
#     publish requires DISCORD_WEBHOOK.
# --------------------------------------------------------------------

# Ensure required commands are available on the system
require_cmd() {
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || { echo "Missing dependency: $c"; exit 1; }
  done
}

# Locate the .briefly config file starting from a base path
# Traverses up to 10 parent directories to find ./ .briefly
find_project_config() {
  local base="${1:-.}"
  local dir
  if [[ -d "$base" ]]; then
    dir="$(cd "$base" && pwd)"
  else
    dir="$(cd "$(dirname "$base")" && pwd)"
  fi

  local i=0
  while [[ "$dir" != "/" && $i -lt 10 ]]; do
    if [[ -f "$dir/.briefly" ]]; then
      echo "$dir/.briefly"; return 0
    fi
    dir="$(dirname "$dir")"
    i=$((i+1))
  done
  return 1
}

# Load project-local configuration
# Exports environment variables used by generate/publish
load_project_config() {
  local base="${1:-.}"
  local cfg
  if ! cfg="$(find_project_config "$base")"; then
    echo "No .briefly found near '$base'. Run: briefly setup [project_dir]" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "$cfg"

  # Defaults
  export OPENAI_API_KEY="${OPENAI_API_KEY:-}"
  export DISCORD_WEBHOOK="${DISCORD_WEBHOOK:-}"
  export DEFAULT_MODEL="${DEFAULT_MODEL:-gpt-4o-mini}"
  export PROJECT_KIND="${PROJECT_KIND:-${DEFAULT_KIND:-api}}"
  export DEFAULT_ENV="${DEFAULT_ENV:-}"
  export DEFAULT_APP_URL="${DEFAULT_APP_URL:-}"

  # Validation is not done here (handled in each command)
}

# Return current UTC timestamp in ISO-8601 format
utc_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Truncate a string to fit Discord embed limits (~4096 chars)
# Adds ellipsis and avoids breaking code blocks if it ends with a backtick
truncate_discord() {
  local s="$1" max=3996 last
  if (( ${#s} <= max )); then printf "%s" "$s"; return; fi
  s="${s:0:max}"
  last="${s: -1}"
  if [[ "$last" == '`' ]]; then s="${s::-1}"; fi
  printf "%s" "$s"$'\n\n…(truncated)'
}
