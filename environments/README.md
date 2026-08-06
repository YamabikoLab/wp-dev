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
| `XDEBUG_VERSION` | Xdebug version installed during the development image build. |
| `CODEX_CLI_VERSION` | Codex CLI version installed during the development image build. |
| `LOGCUT_VERSION` | logcut release version installed during the development image build. Specify the version without the `v` prefix. |
| `WORDPRESS_PORT` | Host port used to access WordPress. |
| `WORDPRESS_SITE_URL` | WordPress URL. Keep its port aligned with `WORDPRESS_PORT`. |
| `WP_PROJECT_DIRECTORY` | WordPress project type: `plugins` or `themes`. |
| `WP_PROJECT_SLUG` | Directory name used under `wp-content/plugins` or `wp-content/themes`. |
| `WP_PROJECT_SOURCE_PATH` | Path from this environment to the external project repository mounted into WordPress and `/workspaces/project`. |

Composer is copied from the `composer:${COMPOSER_VERSION}` image into the WordPress development image. Use a valid Composer image tag, such as `2.8`, and rebuild the image after changing it.

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
