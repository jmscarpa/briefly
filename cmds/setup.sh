#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &>/dev/null && pwd )"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

# --------------------------------------------------------------------
# briefly setup — create/update project-local .briefly
#
# Behavior
# - Creates or updates a .briefly file in the given project directory.
# - If no directory is provided, defaults to the current directory.
# - Prompts the user interactively for all required keys, showing
#   existing values (if any) as defaults.
#
# Requirements
# - User must provide at least OPENAI_API_KEY.
# - The .briefly file is written with mode 600 (private).
#
# Keys stored in .briefly:
#   OPENAI_API_KEY   (required)
#   DISCORD_WEBHOOK  (required for publish)
#   DEFAULT_MODEL    (optional, default: gpt-4o-mini)
#   PROJECT_KIND     (optional, default: api)
#   DEFAULT_ENV      (optional)
#   DEFAULT_APP_URL  (optional)
# --------------------------------------------------------------------

usage() {
  cat <<EOF
briefly setup — create/update project-local .briefly

Usage:
  briefly setup [project_dir]

If no directory is provided, uses current directory.
The .briefly file will include ALL required keys for this project.
EOF
}

project_dir="${1:-.}"
project_dir="$(cd "$project_dir" && pwd)"
cfg_path="${project_dir}/.briefly"

# If config already exists, source it to suggest defaults
[[ -f "$cfg_path" ]] && source "$cfg_path"

# Interactive prompts (defaults shown from existing config or fallback)
read -r -p "OPENAI_API_KEY [${OPENAI_API_KEY:-}]: " in; OPENAI_API_KEY="${in:-${OPENAI_API_KEY:-}}"
read -r -p "DISCORD_WEBHOOK [${DISCORD_WEBHOOK:-}]: " in; DISCORD_WEBHOOK="${in:-${DISCORD_WEBHOOK:-}}"
read -r -p "DEFAULT_MODEL [${DEFAULT_MODEL:-gpt-4o-mini}]: " in; DEFAULT_MODEL="${in:-${DEFAULT_MODEL:-gpt-4o-mini}}"
read -r -p "PROJECT_KIND [${PROJECT_KIND:-api}]: " in; PROJECT_KIND="${in:-${PROJECT_KIND:-api}}"
read -r -p "DEFAULT_ENV [${DEFAULT_ENV:-}]: " in; DEFAULT_ENV="${in:-${DEFAULT_ENV:-}}"
read -r -p "DEFAULT_APP_URL [${DEFAULT_APP_URL:-}]: " in; DEFAULT_APP_URL="${in:-${DEFAULT_APP_URL:-}}"

# Validate required values
[[ -z "$OPENAI_API_KEY" ]] && { echo "OPENAI_API_KEY is required."; exit 1; }

# Write config file with strict permissions
umask 177
cat > "$cfg_path" <<EOF
# briefly project config (do not commit)
OPENAI_API_KEY="$OPENAI_API_KEY"
DISCORD_WEBHOOK="$DISCORD_WEBHOOK"
DEFAULT_MODEL="$DEFAULT_MODEL"
PROJECT_KIND="$PROJECT_KIND"
DEFAULT_ENV="$DEFAULT_ENV"
DEFAULT_APP_URL="$DEFAULT_APP_URL"
EOF
chmod 600 "$cfg_path" 2>/dev/null || true

echo "Project config written to: $cfg_path"
