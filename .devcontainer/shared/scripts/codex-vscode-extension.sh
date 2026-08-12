#!/usr/bin/env bash

set -euo pipefail

case "${CODEX_ENABLED-false}" in
    true)
        if ! command -v code >/dev/null 2>&1; then
            printf 'VS Code code CLI is required to install the OpenAI extension when CODEX_ENABLED=true\n' >&2
            exit 1
        fi

        if code --list-extensions | grep -Fxq 'openai.chatgpt'; then
            echo "OpenAI VS Code extension is already installed."
        else
            code --install-extension openai.chatgpt >/dev/null
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
