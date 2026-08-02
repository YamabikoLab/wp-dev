# wp-dev repository instructions

These instructions apply to the entire repository.

## Repository purpose and boundaries

- This repository provides a reusable local WordPress development environment for externally mounted plugin and theme repositories.
- Keep product source code out of this repository. Plugin and theme code belongs in the repository referenced by `WP_PROJECT_SOURCE_PATH`.
- `docker/compose.shared.yaml` is the shared Compose service definition and the source of truth for services, volumes, and mount behavior.
- `.devcontainer/<environment-name>/` contains thin Dev Container entry points. Do not duplicate shared service definitions there.
- `.devcontainer/shared/` contains shared Docker, PHP, and initialization resources used by all environments.
- `environments/default.env.example` documents the committed environment-variable template. `environments/default.env` is local configuration and must not be committed.
- Read `README.md` before changing setup, mounting, startup, shutdown, or usage behavior.
- Read `environments/README.md` before adding or changing environment definitions.

## Working rules

- Make the smallest change that fully satisfies the current issue.
- Keep the environment generic and reusable across WordPress plugin and theme projects.
- Preserve configuration through `WP_PROJECT_DIRECTORY`, `WP_PROJECT_SLUG`, `WP_PROJECT_SOURCE_PATH`, and `WORKSPACE_NAME`; do not replace these with project-specific paths or names.
- Do not hard-code personal paths, hostnames, machine-specific values, repository names, plugin slugs, theme slugs, or ports that should remain configurable.
- Keep per-environment Compose files thin and include the shared Compose definition instead of copying services.
- Keep documentation aligned with the files, commands, environment variables, paths, and defaults that exist on the current branch.
- Do not add placeholder environments or describe unimplemented services and workflows as available.
- Do not commit generated data, Docker volumes, caches, logs, downloaded dependencies, or build output.
- Do not commit secrets, credentials, tokens, private keys, signed URLs, or populated local environment files.
- Local-development credentials may appear only as clearly documented non-production defaults in committed templates.
- Do not modify an externally mounted plugin or theme repository unless the task explicitly includes that repository.

## Environment definitions

- Each environment name must remain consistent across its directory name, Dev Container configuration, Compose entry point, and environment variables.
- New environments should start from the existing example and shared definitions rather than copying the full stack.
- `COMPOSE_PROJECT_NAME` and `WORDPRESS_PORT` must be unique when multiple environments may run at the same time.
- Keep `WORDPRESS_SITE_URL` aligned with `WORDPRESS_PORT`.
- `WP_PROJECT_DIRECTORY` must resolve to a valid WordPress content directory such as `plugins` or `themes`.
- Mount the external project both into WordPress and into `/workspaces/<workspace-name>` without creating an additional copy of its source.
- Preserve `create_host_path: false` for required bind mounts unless the issue explicitly changes missing-path behavior.

## Documentation responsibilities

- Put direct agent working instructions in `AGENTS.md`.
- Put user-facing setup and operating instructions in `README.md`.
- Put environment-creation instructions in `environments/README.md`.
- Update the relevant documentation whenever a command, directory boundary, environment variable, mount target, default value, or required dependency changes.
- Avoid duplicating long instructions across documents; keep one clear source of truth and link or refer to it where appropriate.

## Validation

- Run only checks applicable to the changed files.
- For Compose, Dev Container, Docker, or environment-definition changes, validate the effective configuration with the active local environment file:

  `docker compose --env-file environments/default.env -f .devcontainer/default/compose.yaml config --quiet`

- When adding another environment, validate that environment's Compose entry point instead of assuming the default environment covers it.
- Run `git diff --check` for repository changes before handoff.
- Documentation-only changes do not require container builds unless they also change commands, paths, configuration, or examples that need verification.
- Never report a command as successful unless it actually ran successfully.
- If a validation command cannot run because local configuration or an external project checkout is unavailable, report that limitation precisely rather than fabricating replacement values.

## External tool boundaries

- Distinguish repository defects from Docker, Docker Compose, Dev Containers, image-registry, host-filesystem, network, or external-project failures.
- Treat GitHub-hosted GitHub Actions runs as the authoritative CI result.
- Do not change shared environment behavior solely to accommodate an unrelated host-specific or external-tool-specific failure.
- Before introducing a workaround that changes mounts, permissions, networking, images, persisted data, or external project files, present the relevant options and obtain approval.

## Destructive operations

- Treat `docker compose down --volumes`, Docker volume deletion, database removal, and WordPress data reset as destructive operations.
- Before running a destructive operation, state which Compose project and persisted data will be affected and obtain approval unless the user explicitly requested that exact reset.
- Do not remove or recreate an external project directory as part of environment troubleshooting.

## Communication

- Do not send routine progress updates while working.
- Continue silently until user approval is required, a blocking issue is found, the requested approach must change, or the task is complete.
- Do not narrate routine file reads, searches, edits, or successful commands.
- Keep all messages concise.

## Approval requests

For simple, low-risk approval requests, report only:

- command or action;
- why approval is required;
- expected effect;
- recommendation.

For destructive, unexpected, or decision-sensitive actions, report:

- observed issue;
- likely cause;
- available options;
- key advantages and disadvantages of each option;
- recommended option and reason.

Do not run an alternative or broaden the scope without approval when the choice could materially affect the repository, Docker environment, persisted data, external project, dependencies, or user data.

## End-of-turn reports

- When files were changed, commands were run, or an implementation plan was produced, end the final response with a Japanese Markdown summary.
- Do not add the structured summary to simple questions, explanations, or requests that do not perform repository work.
- Include `Work performed`, `Changed files`, `Commands run`, `Decision rationale`, `Open items`, and `Next steps`.
- When changes are pushed, include `<repository-url>/compare/<starting-sha>..<pushed-sha>` in the final response.
- Report up to three inefficient activities, such as large reads, repeated searches, or unnecessary command output.
- Under `Commands run`, list every shell command actually run and its result (`success`, `failure`, or `interrupted`), including failed or interrupted commands.
- Write `None` only when a required field has nothing to report.

## Efficient workflow

- Inspect only the files, documentation, history, containers, and environment state required for the requested task.
- Do not inspect Docker volumes, databases, WordPress uploads, dependency trees, caches, logs, or external project source unless the task requires them.
- Before reading large diffs, logs, inspection output, or file listings, inspect a summary or matching-file list and expand only the relevant section.
- Prefer the narrowest relevant validation while iterating.
- Do not re-read unchanged files or repeat successful commands unless new evidence makes it necessary.
- Do not broaden the requested scope unless doing so is necessary to complete the requested outcome.

## Command output

- Use `logcut` only after confirming that the command is running inside a Dev Container where `logcut` is available.
- On the host, run normal diagnostic commands directly. To invoke a finite command in the WordPress container, use the active Compose entry point and environment file.
- Use `logcut` only for finite commands whose successful output is not needed.
- Never use `logcut` for commands containing tokens, passwords, Authorization headers, signed URLs, or other secrets.
- When `logcut` fails, inspect its summary first, then read only the relevant section of the preserved full log when additional context is required.
- Do not rerun a failed command solely to obtain output already available in its preserved log.
- Constrain diagnostic output at the source with service names, paths, filters, formats, ranges, counts, or time windows.
- Do not use `logcut` for Docker inspection commands, interactive commands, watch mode, streaming output, or long-running development services.
