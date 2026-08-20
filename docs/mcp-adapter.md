# MCP Adapter

`wp-dev` can optionally install and activate the official [WordPress MCP Adapter](https://github.com/WordPress/mcp-adapter) for local development.

MCP Adapter is disabled by default. `wp-dev` installs it only when the environment explicitly sets `MCP_ADAPTER_ENABLED=true` and the running WordPress version is 6.9 or later.

## Enable MCP Adapter

The `default` environment uses WordPress 7.1.0 and can enable MCP Adapter. In `environments/default.env`, set:

```dotenv
MCP_ADAPTER_ENABLED=true
MCP_ADAPTER_VERSION=0.5.0
MCP_ADAPTER_SHA256=a13f253c7bf4314b6cce7e238be2d5857eee66242bfe5ff5cb5576f74dc41593
```

Recreate the Dev Container after changing the environment file.

At startup, `wp-dev` downloads the matching official GitHub Release ZIP, verifies its SHA-256 digest, installs it only when the requested version is not already installed, and activates the plugin when necessary.

`MCP_ADAPTER_VERSION` must be a semantic version such as `0.5.0`, without a leading `v`. `MCP_ADAPTER_SHA256` must be the digest for that exact release asset.

## WordPress version support

MCP Adapter itself supports WordPress 6.8 when the separate Abilities API dependency is installed. `wp-dev` intentionally limits this optional integration to WordPress 6.9 or later, where the Abilities API is included in WordPress core.

- `default` currently uses WordPress 7.1.0 and supports this integration.
- `wp704` uses WordPress 7.0.4 and supports this integration.
- `wp683` uses WordPress 6.8.3 and does not install MCP Adapter, even if `MCP_ADAPTER_ENABLED=true` is set accidentally. Startup prints a skip message instead.

The `wp683` example therefore keeps `MCP_ADAPTER_ENABLED=false`.

## STDIO

After MCP Adapter is active, the default server can be started from the Dev Container with WP-CLI:

```bash
wp mcp-adapter serve \
  --server=mcp-adapter-default-server \
  --user=admin
```

Use the administrator account only for trusted local development. The operations exposed to an MCP client depend on the registered WordPress Abilities and their permission callbacks.

## Network and security boundaries

Enabling MCP Adapter does not add another Docker port and does not change the WordPress bind address. WordPress remains published through the existing Compose mapping on `127.0.0.1`.

`wp-dev` does not add an external proxy, telemetry service, or permission bypass for MCP Adapter. If HTTP transport is used, use the existing WordPress port rather than exposing another host port.

Keep MCP connections local and trusted, especially when using an administrator user. Do not place production credentials or sensitive production data in the development environment.
