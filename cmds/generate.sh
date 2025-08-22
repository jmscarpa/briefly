#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# --------------------------------------------------------------------
# briefly generate — turn git commits into a product changelog
#
# Behavior
# - Always uses the CURRENT git repository (pwd).
# - Generates a Markdown changelog using the OpenAI Chat API.
# - Saves output to ./briefly-summary.md by default (or --out FILE).
#
# Requirements
# - Project-local config at ./ .briefly with at least:
#     OPENAI_API_KEY=...
#     DEFAULT_MODEL=gpt-4o-mini   (optional; defaults applied)
# - System tools: git, jq, curl
#
# Flags
#   --date YYYY-MM-DD   Only include commits since this date.
#   --out FILE          Custom output filename (default: briefly-summary.md).
#   -h | --help         Show usage.
#
# Notes
# - If there are no commits in the selected period, the command exits 0 with a message.
# - API errors are surfaced with stderr and a non-zero exit status.
# --------------------------------------------------------------------

usage() {
  cat <<EOF
briefly generate — turn git commits into a changelog

Usage:
  briefly generate [--date YYYY-MM-DD] [--out FILE]
EOF
}

# Ensure required executables exist before continuing.
require_cmd git jq curl

# Parse flags
date_arg=""
out_file="briefly-summary.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --date) date_arg="${2:-}"; shift 2;;
    --out)  out_file="${2:-}"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown flag: $1"; usage; exit 1;;
  esac
done

# Resolve current repo and validate it's a git repository.
repo_abs="$(pwd)"
repo_name="$(basename "$repo_abs")"
[[ -d ".git" ]] || { echo "Not a git repo: $repo_abs"; exit 1; }

# Load project-local configuration (.briefly). Validate required keys.
load_project_config "$repo_abs"
: "${OPENAI_API_KEY:?OPENAI_API_KEY must be set in ./.briefly}"
model="$DEFAULT_MODEL"

# Build git log arguments (with/without --since)
args=(log --date=short --pretty=format:'%h | %ad | %an <%ae> | %s%n%b%n----' --no-merges)
if [[ -n "$date_arg" ]]; then
  args=(log --since="$date_arg" --date=short --pretty=format:'%h | %ad | %an <%ae> | %s%n%b%n----' --no-merges)
fi

# Collect commits as plain text
commits="$(git "${args[@]}")"
if [[ -z "$commits" ]]; then
  echo "No commits ${date_arg:+since $date_arg} in $repo_name."
  exit 0
fi

# Prompt engineering: keep it simple and deterministic
system_msg="You turn git commit logs into a concise weekly *product* changelog in Markdown. Group by area/feature when relevant, highlight notable changes, breaking changes and UX updates."
period_desc="${date_arg:+since $date_arg}"; [[ -z "$period_desc" ]] && period_desc="entire history"
user_ctx="Context:
- Repository: ${repo_name}
- Period: ${period_desc}

Task:
Summarize the commits below into a weekly product changelog in **English**, formatted as Markdown."

# Build a safe JSON payload with jq (handles all escaping)
payload="$(jq -n \
  --arg model "$model" \
  --arg sys "$system_msg" \
  --arg ctx "$user_ctx" \
  --arg commits "$commits" \
  '{model:$model, messages:[{role:"system",content:$sys},{role:"user",content:$ctx},{role:"user",content:$commits}] }')"

# Call OpenAI Chat Completions API
resp="$(curl -sS --fail-with-body https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" \
  -d "$payload" )" || { echo "OpenAI call failed."; exit 1; }

# Surface API-level errors if present
err="$(jq -er '.error // empty' <<<"$resp" 2>/dev/null || true)"
if [[ -n "$err" ]]; then
  jq -r '.error.message' <<<"$resp" >&2
  exit 1
fi

# Extract message content
content="$(jq -r '.choices[0].message.content // empty' <<<"$resp")"
[[ -z "$content" || "$content" == "null" ]] && { echo "Empty content from OpenAI."; exit 1; }

# Print to stdout and save to file
echo "$content" | tee "$out_file" >/dev/null
echo "Changelog saved to: $out_file" >&2
