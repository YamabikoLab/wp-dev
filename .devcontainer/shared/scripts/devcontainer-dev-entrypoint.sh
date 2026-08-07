#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-/home/developer/.codex}"
GH_CONFIG_DIR="${GH_CONFIG_DIR:-/home/developer/.config/gh}"

mkdir -p "${CODEX_HOME}" "${GH_CONFIG_DIR}"

if [[ ! -f "${CODEX_HOME}/hooks.json" ]]; then
    install -m 0644 /usr/local/share/codex-hooks/hooks.json "${CODEX_HOME}/hooks.json"
fi

exec "$@"
