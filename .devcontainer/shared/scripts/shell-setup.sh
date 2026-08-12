#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BASHRC_FILE="${HOME}/.bashrc"
DEVCONTAINER_SHELL_BASHRC="${SCRIPT_DIR}/devcontainer-shell.bash"
SOURCE_LINE="source ${DEVCONTAINER_SHELL_BASHRC}"
LEGACY_BASHRC_BASENAME="bashrc.bak"
OLD_SOURCE_LINE="source ${SCRIPT_DIR}/${LEGACY_BASHRC_BASENAME}"
CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
GH_CONFIG_DIR="${GH_CONFIG_DIR:-${HOME}/.config/gh}"

case "${CODEX_ENABLED-false}" in
    true)
        install -d -m 0700 "${CODEX_HOME}" "${GH_CONFIG_DIR}"
        install -m 0600 /usr/local/share/codex-hooks/hooks.json "${CODEX_HOME}/hooks.json"
        ;;
    false)
        install -d -m 0700 "${GH_CONFIG_DIR}"
        ;;
    *)
        printf 'CODEX_ENABLED must be true or false: %s\n' "${CODEX_ENABLED}" >&2
        exit 1
        ;;
esac

touch "${BASHRC_FILE}"

if grep -Fxq "${OLD_SOURCE_LINE}" "${BASHRC_FILE}"; then
    temp_bashrc="$(mktemp)"
    grep -Fxv "${OLD_SOURCE_LINE}" "${BASHRC_FILE}" >"${temp_bashrc}" || true
    cat "${temp_bashrc}" >"${BASHRC_FILE}"
    rm -f "${temp_bashrc}"
fi

if grep -Fxq "${SOURCE_LINE}" "${BASHRC_FILE}"; then
    echo "Dev container shell customization is already configured."
else
    {
        printf '\n'
        printf '# Dev container shell customization\n'
        printf '%s\n' "${SOURCE_LINE}"
    } >>"${BASHRC_FILE}"

    echo "Dev container shell customization configured."
fi
