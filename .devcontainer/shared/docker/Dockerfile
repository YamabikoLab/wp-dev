ARG WORDPRESS_IMAGE_TAG=7.0.2-php8.3-apache
FROM wordpress:${WORDPRESS_IMAGE_TAG}

ARG NODE_VERSION
ARG PLAYWRIGHT_VERSION
ARG WP_CLI_VERSION
ARG XDEBUG_VERSION
ARG CODEX_CLI_VERSION
ARG LOGCUT_VERSION
ARG LOCAL_UID=1000
ARG LOCAL_GID=1000
ARG LOCALE=ja_JP.UTF-8
ARG TZ=Asia/Tokyo
ARG TARGETARCH

ENV TZ=${TZ} \
    LANG=${LOCALE} \
    PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

RUN groupadd --gid "${LOCAL_GID}" developer \
    && useradd --uid "${LOCAL_UID}" --gid "${LOCAL_GID}" --create-home --shell /bin/bash developer \
    && install -o developer -g developer -m 0700 -d \
        /home/developer \
        /home/developer/.vscode-server \
        /home/developer/.codex \
        /home/developer/.config \
        /home/developer/.config/gh \
    && install -m 0755 -d /usr/local/share/codex-hooks /usr/local/share/wp-dev/apache

COPY --from=composer:2.8 /usr/bin/composer /usr/local/bin/composer

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
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
        gh \
        git \
        vim \
        less \
        locales \
        mariadb-client \
        msmtp \
        msmtp-mta \
        gettext \
        ripgrep \
        unzip \
        xz-utils; \
    architecture="${TARGETARCH:-$(dpkg --print-architecture)}"; \
    case "$architecture" in \
        amd64) \
            node_arch='x64'; \
            logcut_target='x86_64-unknown-linux-gnu' ;; \
        arm64) \
            node_arch='arm64'; \
            logcut_target='aarch64-unknown-linux-gnu' ;; \
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
    logcut_tag="v${LOGCUT_VERSION}"; \
    logcut_archive="logcut-${logcut_tag}-${logcut_target}.tar.gz"; \
    logcut_release_url="https://github.com/YamabikoLab/logcut/releases/download/${logcut_tag}"; \
    curl -fsSLO "${logcut_release_url}/${logcut_archive}"; \
    curl -fsSLO "${logcut_release_url}/SHA256SUMS"; \
    grep " ${logcut_archive}$" SHA256SUMS | sha256sum -c -; \
    tar -xzf "$logcut_archive"; \
    install -m 0755 logcut /usr/local/bin/logcut; \
    rm -f logcut "$logcut_archive" SHA256SUMS; \
    logcut --version > /dev/null; \
    curl -fsSL \
        "https://github.com/wp-cli/wp-cli/releases/download/v${WP_CLI_VERSION}/wp-cli-${WP_CLI_VERSION}.phar" \
        -o /usr/local/bin/wp; \
    chmod +x /usr/local/bin/wp; \
    pecl install "xdebug-${XDEBUG_VERSION}"; \
    docker-php-ext-enable xdebug; \
    gh --version > /dev/null; \
    apt-get purge -y --auto-remove $PHPIZE_DEPS; \
    rm -rf /var/lib/apt/lists/* /tmp/pear ~/.pearrc

RUN npx --yes "playwright@${PLAYWRIGHT_VERSION}" \
        install --with-deps chromium \
    && chmod -R a+rX "${PLAYWRIGHT_BROWSERS_PATH}" \
    && rm -rf /root/.npm /var/lib/apt/lists/*

RUN case "${LOCALE}" in \
        ""|*[![:alnum:]_.@-]*) \
        printf '%s\n' "Invalid LOCALE: ${LOCALE}" >&2; \
        exit 1 ;; \
    esac \
    && printf '%s UTF-8\n' "${LOCALE}" > /etc/locale.gen \
    && locale-gen

COPY docker/wordpress/mu-plugins \
    /usr/src/wordpress/wp-content/mu-plugins
COPY .devcontainer/shared/apache/wordpress-url.conf.template \
    /usr/local/share/wp-dev/apache/wordpress-url.conf.template

RUN npm install --global "@openai/codex@${CODEX_CLI_VERSION}" \
    && codex --version > /dev/null

COPY --chmod=0755 .devcontainer/shared/scripts/terminal-bell.sh \
    /usr/local/share/codex-hooks/terminal-bell.sh
COPY .devcontainer/shared/hooks/hooks.json \
    /usr/local/share/codex-hooks/hooks.json

COPY --chmod=0755 .devcontainer/shared/scripts/devcontainer-entrypoint.sh \
    /usr/local/bin/devcontainer-entrypoint

WORKDIR /var/www/html

ENTRYPOINT ["devcontainer-entrypoint"]
CMD ["apache2-foreground"]
