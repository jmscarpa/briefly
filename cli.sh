#!/usr/bin/env bash
set -euo pipefail

VERSION="0.1.0"

# --------------------------------------------------------------------
# briefly — CLI entrypoint
#
# Behavior
# - Detects the location of the package root (by finding the cmds/ dir).
# - Resolves symlinks/shims (important when installed via npm/Volta).
# - Routes subcommands (setup, generate, publish) to their respective
#   scripts under cmds/.
#
# Commands
#   briefly setup [project_dir]
#       Create or update a .briefly config file in the given project
#       (defaults to current dir).
#
#   briefly generate [--date YYYY-MM-DD] [--out FILE]
#       Generate a changelog from the current git repository.
#       Saves to ./briefly-summary.md by default.
#
#   briefly publish [file.md]
#       Publish a changelog to Discord using project config (.briefly).
#       Defaults to ./briefly-summary.md if no file is given.
#
# Options (used in generate/publish):
#   --kind <type>       Override project kind (e.g. api, frontend).
#   --env-name <name>   Override environment label.
#   --app-url <url>     Override app URL.
#   --mention <text>    Mention a role/user (e.g. "<@&1234567890>").
#   --thread-id <id>    Post into an existing Discord thread.
#
# Environment
#   BRIEFLY_DEBUG=1     Enable debug output (SELF, SCRIPT_DIR, ROOT_DIR).
#
# Notes
# - This script is intended to be published via npm so that `briefly`
#   is available on PATH across macOS/Linux/Windows.
# - The actual logic for each command lives in cmds/*.sh.
# --------------------------------------------------------------------

# --- Resolve SELF (handles npm/Volta shims and symlinks) ---
SELF="${BASH_SOURCE[0]}"
if command -v realpath >/dev/null 2>&1; then
  SELF="$(realpath "$SELF" 2>/dev/null || echo "$SELF")"
fi
SCRIPT_DIR="$( cd -- "$( dirname -- "$SELF" )" &>/dev/null && pwd )"

# --- Ascend to find package root (must contain cmds/) ---
ROOT_DIR="$SCRIPT_DIR"
MAX_ASCEND=5
i=0
while [[ $i -lt $MAX_ASCEND && ! -d "$ROOT_DIR/cmds" ]]; do
  ROOT_DIR="$(dirname "$ROOT_DIR")"
  i=$((i+1))
done

# Fallback: in some environments (e.g. local dev), cmds/ may be in CWD
if [[ ! -d "$ROOT_DIR/cmds" ]]; then
  if [[ -d "./cmds" ]]; then
    ROOT_DIR="$(pwd)"
  fi
fi

if [[ ! -d "$ROOT_DIR/cmds" ]]; then
  echo "briefly: could not locate 'cmds/' directory near '$SCRIPT_DIR'." >&2
  echo "SELF=$SELF" >&2
  echo "SCRIPT_DIR=$SCRIPT_DIR" >&2
  exit 1
fi

# Debug info if BRIEFLY_DEBUG=1
if [[ "${BRIEFLY_DEBUG:-}" == "1" ]]; then
  echo "SELF=$SELF"
  echo "SCRIPT_DIR=$SCRIPT_DIR"
  echo "ROOT_DIR=$ROOT_DIR"
fi

usage() {
  cat <<EOF
briefly ${VERSION} — CLI to generate and publish changelogs

Usage:
  briefly setup [project_dir]
      Create or update a .briefly config file in the given project (default: current dir).

  briefly generate [--date YYYY-MM-DD] [--out FILE]
      Generate a changelog from the current git repository.
      By default saves to ./briefly-summary.md.

  briefly publish [file.md]
      Publish a changelog to Discord using project config (.briefly).
      Defaults to ./briefly-summary.md if no file is given.

Options:
  --kind <type>       Override project kind (e.g. api, frontend).
  --env-name <name>   Override environment name.
  --app-url <url>     Override app URL.
  --mention <text>    Mention a role or user (e.g. <@&1234567890>).
  --thread-id <id>    Post into an existing thread.

Run 'briefly <command> --help' for more details on each command.
EOF
}

# Route subcommands
cmd="${1:-}"
case "$cmd" in
  setup)    shift; "${ROOT_DIR}/cmds/setup.sh" "$@";;
  generate) shift; "${ROOT_DIR}/cmds/generate.sh" "$@";;
  publish)  shift; "${ROOT_DIR}/cmds/publish.sh" "$@";;
  -h|--help|help|"") usage;;
  *) echo "Unknown command: $cmd"; usage; exit 1;;
esac
