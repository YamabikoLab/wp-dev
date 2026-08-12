#!/usr/bin/env bash

set -euo pipefail

find_code_server() {
    local vscode_server_root="${HOME}/.vscode-server"
    local code_server

    if [ ! -d "${vscode_server_root}" ]; then
        return 1
    fi

    code_server="$(
        find "${vscode_server_root}" \
            -path '*/bin/code-server' \
            -type f \
            -perm -u+x \
            -print \
            -quit
    )"

    if [ -z "${code_server}" ]; then
        return 1
    fi

    printf '%s\n' "${code_server}"
}

case "${CODEX_ENABLED-false}" in
    true)
        if ! code_server="$(find_code_server)"; then
            printf 'VS Code Server code-server is required to install the OpenAI extension when CODEX_ENABLED=true\n' >&2
            exit 1
        fi

        if "${code_server}" --list-extensions | grep -Fxq 'openai.chatgpt'; then
            echo "OpenAI VS Code extension is already installed."
        else
            "${code_server}" --install-extension openai.chatgpt >/dev/null
            echo "OpenAI VS Code extension installed."
        fi
        ;;
    false)
        ;;
    *)
        printf 'CODEX_ENABLED must be true or false: %s\n' "${CODEX_ENABLED}" >&2
        exit 1
        ;;
esac
