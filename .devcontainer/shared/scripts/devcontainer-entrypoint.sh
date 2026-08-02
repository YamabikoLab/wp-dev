#!/usr/bin/env bash
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-/var/www/.codex}"
GH_CONFIG_DIR="${GH_CONFIG_DIR:-/var/www/.config/gh}"
MU_PLUGIN_SOURCE="/usr/src/wordpress/wp-content/mu-plugins/development.php"
MU_PLUGIN_TARGET_DIR="/var/www/html/wp-content/mu-plugins"

mkdir -p \
    /var/www/html \
    "${MU_PLUGIN_TARGET_DIR}" \
    "${CODEX_HOME}" \
    "${GH_CONFIG_DIR}"

install -o www-data -g www-data -m 0644 \
    "${MU_PLUGIN_SOURCE}" \
    "${MU_PLUGIN_TARGET_DIR}/development.php"

install -o www-data -g www-data -m 0644 \
    /usr/local/share/codex-hooks/hooks.json \
    "${CODEX_HOME}/hooks.json"

chown -R www-data:www-data \
    /var/www/html \
    "${CODEX_HOME}" \
    "${GH_CONFIG_DIR}"

exec docker-entrypoint.sh "$@"
