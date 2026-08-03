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
| `WORDPRESS_IMAGE_TAG` | WordPress image tag used to build the development container. |
| `LOGCUT_VERSION` | logcut release version installed during the development image build. Specify the version without the `v` prefix. |
| `WORDPRESS_PORT` | Host port used to access WordPress. |
| `WORDPRESS_SITE_URL` | WordPress URL. Keep its port aligned with `WORDPRESS_PORT`. |
| `WP_PROJECT_DIRECTORY` | WordPress project type: `plugins` or `themes`. |
| `WP_PROJECT_SLUG` | Directory name used under `wp-content/plugins` or `wp-content/themes`. |
| `WP_PROJECT_SOURCE_PATH` | Path from this environment to the external project repository mounted into WordPress and the workspace. |
| `WORKSPACE_NAME` | Directory name used for the project under `/workspaces`. |

During the image build, the matching amd64 or arm64 logcut release archive and `SHA256SUMS` are downloaded from GitHub. The archive is installed only after its checksum has been verified.

The Dev Container opens `/workspaces` as its workspace. Use `cdw` to move to the project directory selected by `WORKSPACE_NAME`.

The database and WordPress administrator credentials in the templates are local-development defaults only. Replace them when necessary, and never store real credentials in the repository.

Future WordPress environments should follow the same naming pair: `wp***.env.example` for the committed template and `wp***.env` for the ignored local file.

## Validate the configuration

```bash
docker compose --env-file environments/default.env -f .devcontainer/default/compose.yaml config
docker compose --env-file environments/wp683.env -f .devcontainer/wp683/compose.yaml config
```

Then open the repository in Visual Studio Code and select the matching Dev Container configuration.

The Compose service definitions remain in `docker/compose.shared.yaml`. Do not copy them into the environment file or the Dev Container-specific Compose file.
