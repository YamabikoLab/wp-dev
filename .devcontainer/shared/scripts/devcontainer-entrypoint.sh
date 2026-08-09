#!/usr/bin/env bash
set -euo pipefail

MU_PLUGIN_SOURCE="/usr/src/wordpress/wp-content/mu-plugins/development.php"
MU_PLUGIN_TARGET_DIR="/var/www/html/wp-content/mu-plugins"
APACHE_URL_CONFIG_TEMPLATE="/usr/local/share/wp-dev/apache/wordpress-url.conf.template"
APACHE_URL_CONFIG="/etc/apache2/conf-available/wp-dev-wordpress-url.conf"
WORDPRESS_CONFIG_FILE="/var/www/html/wp-config.php"
WORDPRESS_URL_MARKER="// wp-dev: canonical-url"

if [[ ! "${WORDPRESS_PORT:-}" =~ ^[0-9]+$ ]] || (( WORDPRESS_PORT < 1 || WORDPRESS_PORT > 65535 )); then
    printf 'Invalid WORDPRESS_PORT: %s\n' "${WORDPRESS_PORT:-}" >&2
    exit 1
fi

if [[ ! "${WORDPRESS_HOST:-}" =~ ^[A-Za-z0-9.-]+$ ]]; then
    printf 'Invalid WORDPRESS_HOST: %s\n' "${WORDPRESS_HOST:-}" >&2
    exit 1
fi

if [[ "${WORDPRESS_PORT}" == "80" ]]; then
    rm -f "${APACHE_URL_CONFIG}"
    a2disconf wp-dev-wordpress-url >/dev/null 2>&1 || true
else
    envsubst '${WORDPRESS_HOST} ${WORDPRESS_PORT}' \
        < "${APACHE_URL_CONFIG_TEMPLATE}" \
        > "${APACHE_URL_CONFIG}"
    a2enconf wp-dev-wordpress-url >/dev/null
fi

install -o developer -g developer -m 0700 -d /workspaces

docker-ensure-installed.sh true

mkdir -p \
    /var/www/html \
    "${MU_PLUGIN_TARGET_DIR}"

install -o www-data -g www-data -m 0644 \
    "${MU_PLUGIN_SOURCE}" \
    "${MU_PLUGIN_TARGET_DIR}/development.php"

if [[ -f "${WORDPRESS_CONFIG_FILE}" ]] \
    && ! grep -Fq "${WORDPRESS_URL_MARKER}" "${WORDPRESS_CONFIG_FILE}"; then
    php -r '
        $path = $argv[1];
        $contents = file_get_contents($path);
        if ($contents === false) {
            fwrite(STDERR, "Failed to read wp-config.php\n");
            exit(1);
        }

        $needle = "require_once ABSPATH . '\''wp-settings.php'\'';";
        $block = <<<'\''PHP'\''
// wp-dev: canonical-url
if (!defined('\''WP_HOME'\'')) {
    define('\''WP_HOME'\'', getenv('\''WORDPRESS_URL'\''));
}
if (!defined('\''WP_SITEURL'\'')) {
    define('\''WP_SITEURL'\'', getenv('\''WORDPRESS_URL'\''));
}

PHP;

        $count = 0;
        $updated = str_replace($needle, $block . $needle, $contents, $count);
        if ($count !== 1) {
            fwrite(STDERR, "Could not locate wp-settings.php bootstrap in wp-config.php\n");
            exit(1);
        }
        if (file_put_contents($path, $updated) === false) {
            fwrite(STDERR, "Failed to update wp-config.php\n");
            exit(1);
        }
    ' "${WORDPRESS_CONFIG_FILE}"
fi

: "${WORDPRESS_URL:?WORDPRESS_URL is required}"
: "${WORDPRESS_SITE_TITLE:?WORDPRESS_SITE_TITLE is required}"
: "${WORDPRESS_ADMIN_USER:?WORDPRESS_ADMIN_USER is required}"
: "${WORDPRESS_ADMIN_PASSWORD:?WORDPRESS_ADMIN_PASSWORD is required}"
: "${WORDPRESS_ADMIN_EMAIL:?WORDPRESS_ADMIN_EMAIL is required}"

wp_cli=(wp --allow-root --path=/var/www/html)

if ! "${wp_cli[@]}" core is-installed >/dev/null 2>&1; then
    "${wp_cli[@]}" core install \
        --url="${WORDPRESS_URL}" \
        --title="${WORDPRESS_SITE_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN_USER}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --skip-email
elif user_id="$("${wp_cli[@]}" user get "${WORDPRESS_ADMIN_USER}" --field=ID 2>/dev/null)"; then
    "${wp_cli[@]}" user update "${user_id}" \
        --user_pass="${WORDPRESS_ADMIN_PASSWORD}" \
        --user_email="${WORDPRESS_ADMIN_EMAIL}" \
        --role=administrator \
        --skip-email
else
    "${wp_cli[@]}" user create \
        "${WORDPRESS_ADMIN_USER}" \
        "${WORDPRESS_ADMIN_EMAIL}" \
        --user_pass="${WORDPRESS_ADMIN_PASSWORD}" \
        --role=administrator
fi

exec "$@"
