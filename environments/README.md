# Environment configuration

This directory contains the project-specific values used by each Dev Container configuration.

The default Dev Container loads `environments/default.env`. This repository tracks `environments/default.env.example` as the template, while the local `default.env` file must not be committed.

## Create the local environment file

Copy the template before opening the Dev Container:

```bash
cp environments/default.env.example environments/default.env
```

Update at least the following values for the WordPress project being developed:

| Variable | Purpose |
| --- | --- |
| `COMPOSE_PROJECT_NAME` | Unique Docker Compose project name used to isolate containers, networks, and volumes. |
| `WORDPRESS_IMAGE_TAG` | WordPress image tag used to build the development container. |
| `WORDPRESS_PORT` | Host port used to access WordPress. |
| `WORDPRESS_SITE_URL` | WordPress URL. Keep its port aligned with `WORDPRESS_PORT`. |
| `WP_PROJECT_DIRECTORY` | WordPress project type: `plugins` or `themes`. |
| `WP_PROJECT_SLUG` | Directory name used under `wp-content/plugins` or `wp-content/themes`. |
| `WP_PROJECT_SOURCE_PATH` | Path from this environment to the external project repository mounted into WordPress and the workspace. |
| `WORKSPACE_NAME` | Directory name used for the project under `/workspaces`. |

The Dev Container opens `/workspaces` as its workspace. Use `cdw` to move to the project directory selected by `WORKSPACE_NAME`.

The database and WordPress administrator credentials in `default.env.example` are local-development defaults only. Replace them when necessary, and never store real credentials in the repository.

## Validate the configuration

Run Docker Compose configuration validation after editing `default.env`:

```bash
docker compose -f .devcontainer/default/compose.yaml config
```

Then open the repository in Visual Studio Code and select the `default` Dev Container configuration.

The Compose service definitions remain in `docker/compose.shared.yaml`. Do not copy them into the environment file or the Dev Container-specific Compose file.
