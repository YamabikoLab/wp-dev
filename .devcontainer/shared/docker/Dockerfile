# syntax=docker/dockerfile:1

ARG COMPOSER_VERSION=2.8
ARG WORDPRESS_IMAGE_TAG=7.0.2-php8.3-apache
FROM composer:${COMPOSER_VERSION} AS composer-source
FROM wordpress:${WORDPRESS_IMAGE_TAG}

ARG NODE_VERSION
ARG PLAYWRIGHT_VERSION
ARG PLAYWRIGHT_ONLY_SHELL=false
ARG WP_CLI_VERSION
ARG XDEBUG_VERSION
ARG CODEX_CLI_VERSION
ARG LOGCUT_VERSION
ARG LOCAL_UID=1000
ARG LOCAL_GID=1000
ARG LOCALE=ja_JP.UTF-8
ARG TZ=Asia/Tokyo
ARG TARGETARCH

ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl; \
    install -m 0755 -d /etc/apt/keyrings; \
    curl -fsSL https://download.docker.com/linux/debian/gpg \
        -o /etc/apt/keyrings/docker.asc; \
    chmod a+r /etc/apt/keyrings/docker.asc; \
    curl -fsSL \
        https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        -o /etc/apt/keyrings/githubcli-archive-keyring.gpg; \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg; \
    . /etc/os-release; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian ${VERSION_CODENAME} stable" \
        > /etc/apt/sources.list.d/docker.list; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        docker-ce-cli \
        docker-compose-plugin \
        gettext \
        gh \
        git \
        less \
        locales \
        mariadb-client \
        msmtp \
        msmtp-mta \
        ripgrep \
        unzip \
        vim \
        xz-utils; \
    gh --version > /dev/null; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    architecture="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "$architecture" in \
        amd64) node_arch='x64' ;; \
        arm64) node_arch='arm64' ;; \
        *) \
            echo "Unsupported architecture: $architecture" >&2; \
            exit 1 ;; \
    esac; \
    node_archive="node-v${NODE_VERSION}-linux-${node_arch}.tar.xz"; \
    curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/${node_archive}"; \
    curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt"; \
    grep " ${node_archive}$" SHASUMS256.txt | sha256sum -c -; \
    tar -xJf "$node_archive" -C /usr/local --strip-components=1; \
    rm -f "$node_archive" SHASUMS256.txt; \
    node --version > /dev/null; \
    npm --version > /dev/null

RUN --mount=type=cache,target=/root/.npm \
    set -eux; \
    case "${PLAYWRIGHT_ONLY_SHELL}" in \
        true) set -- --only-shell ;; \
        false) set -- ;; \
        *) \
            echo "PLAYWRIGHT_ONLY_SHELL must be true or false: ${PLAYWRIGHT_ONLY_SHELL}" >&2; \
            exit 1 ;; \
    esac; \
    npx --yes "playwright@${PLAYWRIGHT_VERSION}" \
        install --with-deps "$@" chromium; \
    chmod -R a+rX "${PLAYWRIGHT_BROWSERS_PATH}"; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    curl -fsSL \
        "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar" \
        -o /usr/local/bin/wp; \
    chmod +x /usr/local/bin/wp; \
    wp --allow-root --version > /dev/null

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends $PHPIZE_DEPS; \
    pecl install "xdebug-${XDEBUG_VERSION}"; \
    docker-php-ext-enable xdebug; \
    php --ri xdebug > /dev/null; \
    apt-get purge -y --auto-remove $PHPIZE_DEPS; \
    rm -rf /var/lib/apt/lists/* /tmp/pear ~/.pearrc

RUN set -eux; \
    architecture="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "$architecture" in \
        amd64) logcut_target='x86_64-unknown-linux-gnu' ;; \
        arm64) logcut_target='aarch64-unknown-linux-gnu' ;; \
        *) \
            echo "Unsupported architecture: $architecture" >&2; \
            exit 1 ;; \
    esac; \
    logcut_tag="v${LOGCUT_VERSION}"; \
    logcut_archive="logcut-${logcut_tag}-${logcut_target}.tar.gz"; \
    logcut_release_url="https://github.com/YamabikoLab/logcut/releases/download/${logcut_tag}"; \
    curl -fsSLO "${logcut_release_url}/${logcut_archive}"; \
    curl -fsSLO "${logcut_release_url}/SHA256SUMS"; \
    grep " ${logcut_archive}$" SHA256SUMS | sha256sum -c -; \
    tar -xzf "$logcut_archive"; \
    install -m 0755 logcut /usr/local/bin/logcut; \
    rm -f logcut "$logcut_archive" SHA256SUMS; \
    logcut --version > /dev/null

RUN --mount=type=cache,target=/root/.npm \
    npm install --global "@openai/codex@${CODEX_CLI_VERSION}" \
    && codex --version > /dev/null

COPY --from=composer-source /usr/bin/composer /usr/local/bin/composer
RUN composer --version > /dev/null

RUN case "${LOCALE}" in \
        ""|*[![:alnum:]_.@-]*) \
        printf '%s\n' "Invalid LOCALE: ${LOCALE}" >&2; \
        exit 1 ;; \
    esac \
    && printf '%s UTF-8\n' "${LOCALE}" > /etc/locale.gen \
    && locale-gen

ENV TZ=${TZ} \
    LANG=${LOCALE}

RUN groupmod --gid "${LOCAL_GID}" www-data \
    && usermod --uid "${LOCAL_UID}" --gid "${LOCAL_GID}" www-data \
    && mkdir -p /var/www/.vscode-server /var/www/.codex /var/www/.config/gh \
    && chown -R www-data:www-data /var/www \
    && install -m 0755 -d /usr/local/share/codex-hooks

COPY docker/wordpress/mu-plugins \
    /usr/src/wordpress/wp-content/mu-plugins

COPY --chmod=0755 .devcontainer/shared/scripts/terminal-bell.sh \
    /usr/local/share/codex-hooks/terminal-bell.sh
COPY .devcontainer/shared/hooks/hooks.json \
    /usr/local/share/codex-hooks/hooks.json

COPY --chmod=0755 .devcontainer/shared/scripts/devcontainer-entrypoint.sh \
    /usr/local/bin/devcontainer-entrypoint

WORKDIR /var/www/html

ENTRYPOINT ["devcontainer-entrypoint"]
CMD ["apache2-foreground"]
