# Environment configuration

This directory contains the project-specific values used by each Dev Container configuration.

The default Dev Container loads `environments/default.env`. This repository tracks `environments/default.env.example` as the template, while the local `default.env` file must not be committed.

The `wp683` Dev Container loads `environments/default.env` first, then applies the committed `environments/wp683.env` overrides for WordPress 6.8.3, its Compose project name, and its host ports.

## Create the local environment file

Copy the template before opening either Dev Container:

```bash
cp environments/default.env.example environments/default.env
```

Update the project-specific values in `environments/default.env`, including `WP_PROJECT_DIRECTORY`, `WP_PROJECT_SLUG`, `WP_PROJECT_SOURCE_PATH`, and `WORKSPACE_NAME`.

Do not create `wp683.env.example`. The committed `wp683.env` file contains only the environment-specific overrides and reuses the project settings from `default.env`.

## Validate the configurations

```bash
docker compose -f .devcontainer/default/compose.yaml config --quiet
docker compose -f .devcontainer/wp683/compose.yaml config --quiet
```

Then open the repository in Visual Studio Code and select either `wp-dev: default` or `wp-dev: wp683`.

The Compose service definitions remain in `docker/compose.shared.yaml`. Do not copy them into the Dev Container-specific Compose files.
