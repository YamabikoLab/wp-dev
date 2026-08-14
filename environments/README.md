# Environment configuration

This directory contains the project-specific values used by each Dev Container configuration.

Each Dev Container loads its matching local environment file:

- `default` loads `environments/default.env`.
- `wp683` loads `environments/wp683.env`.

The repository tracks matching `.env.example` templates, while local `.env` files must not be committed.

## Create a local environment file

Copy the template for the environment you want to use:

```bash
cp environments/default.env.example environments/default.env
cp environments/wp683.env.example environments/wp683.env
```

Update at least the following values for the WordPress project being developed:

| Variable | Purpose |
| --- | --- |
| `COMPOSE_PROJECT_NAME` | Unique Docker Compose project name used to isolate containers, networks, and volumes. |
| `COMPOSER_VERSION` | Composer image tag used to provide the Composer executable during the development image build. |
| `WORDPRESS_IMAGE_TAG` | WordPress image tag used to build the development container. |
| `NODE_VERSION` | Node.js version installed during the development image build. |
| `PLAYWRIGHT_VERSION` | Playwright version used to install the managed Chromium browser and its runtime dependencies. |
| `PLAYWRIGHT_ONLY_SHELL` | Set to `true` to install only Chromium headless shell, or `false` to keep the full Chromium installation. |
| `WP_CLI_VERSION` | WP-CLI version installed during the development image build. |
| `WP_CLI_SHA256` | Expected SHA-256 digest for the WP-CLI PHAR matching `WP_CLI_VERSION`. |
| `XDEBUG_VERSION` | Xdebug version installed during the development image build. |
| `CODEX_ENABLED` | Optional Codex integration. Defaults to `false`; set to `true` to install and initialize Codex. |
| `CODEX_CLI_VERSION` | Codex CLI version used only when `CODEX_ENABLED=true`. |
| `LOGCUT_VERSION` | logcut release version installed during the development image build. Specify the version without the `v` prefix. |
| `WORDPRESS_HOST` | Host name used by the canonical WordPress URL. |
| `WORDPRESS_PORT` | WordPress port used by both the host URL and the additional Apache listener inside the Dev Container. |
| `WORDPRESS_LOCALE` | WordPress locale used only when WordPress is installed for the first time. Defaults to `ja`. |
| `EDITOR_MODE` | Post editor mode for compatibility testing. Use `default` normally or `non-iframe` to force the legacy non-iframe post editor where the selected WordPress version still supports it. |
| `PHP_DISPLAY_ERRORS` | PHP error display for pre-WordPress/direct PHP diagnostics. Keep `Off` normally; temporarily set `On` only when required. WordPress requests still keep `WP_DEBUG_DISPLAY=false`. |
| `WP_PROJECT_DIRECTORY` | WordPress project type: `plugins` or `themes`. |
| `WP_PROJECT_SLUG` | Directory name used under `wp-content/plugins` or `wp-content/themes`. |
| `WP_PROJECT_SOURCE_PATH` | Path from this environment to the external project repository mounted into WordPress and `/workspaces/project`. |

`WORDPRESS_URL` is derived by Compose from `WORDPRESS_HOST` and `WORDPRESS_PORT`. Do not add a separate `WORDPRESS_URL` value to an environment file. The same URL is used by WordPress and exposed as `WP_BASE_URL` for Playwright. See [WordPress URL configuration](../docs/wordpress-url.md) for the networking and canonical-URL design.

### Codex integration

Codex support is optional and disabled by default:

```dotenv
CODEX_ENABLED=false
```

Set `CODEX_ENABLED=true` and rebuild the Dev Container to enable it. When enabled, wp-dev installs the pinned `CODEX_CLI_VERSION`, initializes `/home/developer/.codex`, installs the Codex hooks, records the VS Code terminal TTY for the notification hook, and installs the `openai.chatgpt` VS Code extension.

When disabled, the Codex CLI and OpenAI extension are not installed automatically, and Codex-specific initialization is skipped. `CODEX_ENABLED` accepts only `true` or `false`; any other value fails clearly during image build or shell setup.

`CODEX_CLI_VERSION` remains pinned in the environment templates but is used only when Codex is enabled.

### WordPress locale

`WORDPRESS_LOCALE` controls the locale passed to `wp core install` when WordPress is not installed yet. The default is Japanese:

```dotenv
WORDPRESS_LOCALE=ja
```

For an English installation, set for example:

```dotenv
WORDPRESS_LOCALE=en_US
```

This setting is intentionally separate from `LOCALE`, which configures the container/OS locale. Changing `WORDPRESS_LOCALE` after WordPress has already been installed does not change the existing site's language and is not kept in sync automatically.

### PHP error display

`PHP_DISPLAY_ERRORS=Off` is the safe default. PHP reads this environment value from the shared `php.ini` for both `display_errors` and `display_startup_errors`.

Temporarily set it to `On` only when diagnosing errors before WordPress initialization, direct PHP execution, or startup errors, then recreate the target container. Restore it to `Off` after diagnosis.

WordPress normal requests keep `WP_DEBUG_DISPLAY=false`, so this opt-in is intentionally not a switch for displaying WordPress runtime errors in the browser.

See [Development data retention and reset](../docs/data-retention.md) for the surrounding data-handling policy.

### Editor mode

`EDITOR_MODE=default` leaves WordPress editor selection unchanged.

`EDITOR_MODE=non-iframe` registers a hidden `wp-dev/editor-mode-marker` block with Block API version 2. In WordPress 6.8, registering that lower-versioned block is enough to select the non-iframe post editor. In WordPress 7.0, the editor checks blocks actually present in the post, so wp-dev automatically inserts the marker when the post editor opens. The marker renders no frontend output and is hidden from the inserter.

When the environment is switched back to `EDITOR_MODE=default`, the same marker is registered as Block API version 3. Existing posts containing the marker therefore return to WordPress's normal iframe decision without requiring the marker to be removed.

This compatibility switch applies to the post editor only. WordPress is moving toward always using the iframe editor, so `non-iframe` is intended only for testing versions that still provide the fallback.

Composer is copied from the `composer:${COMPOSER_VERSION}` image into the WordPress development image. Use a valid Composer image tag, such as `2.8`, and rebuild the image after changing it.

During the image build, the WP-CLI PHAR is checked against `WP_CLI_SHA256` before it is made executable. When `WP_CLI_VERSION` is updated, update `WP_CLI_SHA256` to the digest published for the matching release asset.

During the image build, the matching amd64 or arm64 logcut release archive and `SHA256SUMS` are downloaded from GitHub. The archive is installed only after its checksum has been verified.

Playwright installs Chromium and its runtime dependencies into `/ms-playwright`. The browser files are readable and executable by the `www-data` user. Leave `PLAYWRIGHT_ONLY_SHELL=false` when headed mode, code generation, or the full Chromium executable is required. Set it to `true` for headless-only test environments to avoid downloading the full Chromium package. Values other than `true` or `false` cause the image build to fail.

Set `PLAYWRIGHT_VERSION` to the same version as the external project's `@playwright/test` or `playwright` dependency. When that project dependency is updated, update the environment file and rebuild the development image so `/ms-playwright` contains the matching browser executable.

The Dev Container opens the external project directly at `/workspaces/project`.

The database and WordPress administrator credentials in the templates are local-development defaults only. Replace them when necessary, and never store real credentials in the repository.

Future WordPress environments should follow the same naming pair: `wp***.env.example` for the committed template and `wp***.env` for the ignored local file.

## Validate the configuration

```bash
docker compose --env-file environments/default.env -f .devcontainer/default/compose.yaml config
docker compose --env-file environments/wp683.env -f .devcontainer/wp683/compose.yaml config
```

Then open the repository in Visual Studio Code and select the matching Dev Container configuration.

The Compose service definitions remain in `docker/compose.shared.yaml`. Do not copy them into the environment file or the Dev Container-specific Compose file.
