#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# --------------------------------------------------------------------
# briefly publish — send a changelog to Discord
#
# Behavior
# - Uses project-local config (./.briefly) to find the Discord webhook.
# - Publishes a Markdown changelog as a Discord embed.
# - If no file is given, uses ./briefly-summary.md in the current repo.
# - Supports posting into an existing Discord thread (via --thread-id).
#
# Requirements
# - Project-local .briefly with at least:
#     DISCORD_WEBHOOK=...
#     (OPTIONAL) DEFAULT_APP_URL=..., DEFAULT_ENV=..., PROJECT_KIND=...
# - System tools: jq, curl
#
# Flags
#   [file.md]             Optional path to the changelog file (default: ./briefly-summary.md)
#   --kind <type>         Override project kind (e.g. api, frontend)
#   --env-name <name>     Override environment label (footer text)
#   --app-url <url>       Override URL (linked in the embed title)
#   --mention <text>      Mention a role/user (e.g. "<@&1234567890>")
#   --thread-id <id>      Post into an existing Discord thread
#   -h | --help           Show usage
#
# Notes
# - Discord embed description hard limit is ~4096 chars; we truncate with margin.
# - API errors are printed to stderr; the script exits with a non-zero code.
# --------------------------------------------------------------------

usage() {
  cat <<EOF
briefly publish — send a changelog to Discord

Usage:
  briefly publish [file.md]
                  [--kind <type>] [--env-name NAME] [--app-url URL]
                  [--mention TEXT]
                  [--thread-id ID]

Defaults:
  - If no file is passed, uses ./briefly-summary.md from the current repo.
EOF
}

require_cmd jq curl

# Determine changelog file
file="${1:-}"
if [[ -n "$file" && "$file" != --* ]]; then
  shift
else
  repo_abs="$(pwd)"
  file="${repo_abs}/briefly-summary.md"
fi

[[ -f "$file" ]] || { echo "Changelog file not found: $file"; exit 1; }

# Parse flags
kind=""
env_name=""
app_url=""
mention=""
thread_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kind)      kind="${2:-}"; shift 2;;
    --env-name)  env_name="${2:-}"; shift 2;;
    --app-url)   app_url="${2:-}"; shift 2;;
    --mention)   mention="${2:-}"; shift 2;;
    --thread-id) thread_id="${2:-}"; shift 2;;
    -h|--help)   usage; exit 0;;
    *) echo "Unknown flag: $1"; usage; exit 1;;
  esac
done

# Resolve repo name (used in embed title)
repo_abs="$(cd "$(dirname "$file")" && pwd)"
repo_name="$(basename "$repo_abs")"

# Load project-local configuration and validate webhook
load_project_config "$repo_abs"
: "${DISCORD_WEBHOOK:?DISCORD_WEBHOOK must be set in ./.briefly}"

proj_upper="$(echo "$repo_name" | tr '[:lower:]' '[:upper:]')"
kind_upper="$(echo "${kind:-$PROJECT_KIND}" | tr '[:lower:]' '[:upper:]')"
title="🚀 ${proj_upper} — ${kind_upper}"

# Read file content and truncate for Discord if necessary
body="$(cat "$file")"
body="$(truncate_discord "$body")"
ts="$(utc_now)"

# Build JSON payload
payload="$(jq -n \
  --arg title "$title" \
  --arg body "$body" \
  --arg ts "$ts" \
  --arg url "${app_url:-$DEFAULT_APP_URL}" \
  --arg env "${env_name:-$DEFAULT_ENV}" \
  --arg mention "${mention:-}" '
  {
    username: "Deploy Bot",
    content: (if $mention != "" then $mention else null end),
    embeds: [
      {
        title: $title,
        description: $body,
        url: (if $url != "" then $url else null end),
        color: 3066993,
        footer: (if $env != "" then {text: ("Env: " + $env)} else null end),
        timestamp: $ts
      }
    ]
  } | with_entries(select(.value != null))
')"

# Append ?thread_id=... if provided
url="$DISCORD_WEBHOOK"
[[ -n "$thread_id" ]] && url="${url}?thread_id=$thread_id"

# Send request
code="$(curl -sS -o /tmp/briefly_discord_resp.txt -w "%{http_code}" \
  -X POST "$url" -H "Content-Type: application/json" -d "$payload" || true)"

if [[ "$code" != "204" && "$code" != "200" ]]; then
  echo "Discord error (HTTP $code):"
  cat /tmp/briefly_discord_resp.txt
  exit 1
fi

echo "Changelog published to Discord: $title"
[[ -n "$thread_id" ]] && echo "Posted into thread: $thread_id"
