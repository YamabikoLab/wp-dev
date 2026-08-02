# Environment configuration

This directory separates project-specific settings from committed environment presets.

- `environments/.env` contains settings for the external plugin or theme repository and must not be committed.
- `environments/default.env` selects the default WordPress environment.
- `environments/wp683.env` selects WordPress 6.8.3 with PHP 8.3 and Apache.

## Create the project settings file

Copy the shared template before opening either Dev Container:

```bash
cp environments/.env.example environments/.env
```

Update at least the following values:

| Variable | Purpose |
| --- | --- |
| `PROJECT_NAME` | Base name used to create an isolated Compose project for each environment. |
| `WP_PROJECT_DIRECTORY` | WordPress project type: `plugins` or `themes`. |
| `WP_PROJECT_SLUG` | Directory name used under `wp-content/plugins` or `wp-content/themes`. |
| `WP_PROJECT_SOURCE_PATH` | Path from this repository to the external project repository. |
| `WORKSPACE_NAME` | Directory name used for the project under `/workspaces`. |

Database credentials, administrator credentials, UID/GID, locale, and timezone are also shared through `environments/.env`.

The Dev Container opens `/workspaces` as its workspace. Use `cdw` to move to the project directory selected by `WORKSPACE_NAME`.

## Environment presets

| Environment | WordPress image | WordPress URL | Mailpit URL | Compose project suffix |
| --- | --- | --- | --- | --- |
| `default` | `wordpress:7.0.2-php8.3-apache` | `http://127.0.0.1:8080` | `http://127.0.0.1:8025` | `-default` |
| `wp683` | `wordpress:6.8.3-php8.3-apache` | `http://127.0.0.1:8081` | `http://127.0.0.1:8026` | `-wp683` |

The preset files contain only environment-specific overrides. Shared Compose services remain in `docker/compose.shared.yaml`.

## Validate the configurations

```bash
docker compose -f .devcontainer/default/compose.yaml config --quiet
docker compose -f .devcontainer/wp683/compose.yaml config --quiet
```

Then open the repository in Visual Studio Code and select either `wp-dev: default` or `wp-dev: wp683`.

## Stop an environment

```bash
docker compose -f .devcontainer/default/compose.yaml down
docker compose -f .devcontainer/wp683/compose.yaml down
```

Add `--volumes` only when intentionally deleting that environment's persisted WordPress and database data.
