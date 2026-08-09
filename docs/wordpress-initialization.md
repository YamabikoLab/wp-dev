# WordPress initial setup and administrator sync

`wp-dev` treats the selected environment file as the source of truth for the local WordPress administrator used by development tools and Playwright.

## Environment variables

The WordPress container receives these values:

- `WORDPRESS_SITE_TITLE`
- `WORDPRESS_ADMIN_USER`
- `WORDPRESS_ADMIN_PASSWORD`
- `WORDPRESS_ADMIN_EMAIL`
- `WORDPRESS_URL`, derived by Docker Compose from `WORDPRESS_HOST` and `WORDPRESS_PORT`

`WP_USERNAME` and `WP_PASSWORD` are derived from the same administrator username and password, so Playwright and WordPress use matching credentials.

## Startup behavior

Before Apache starts, the container first uses the WordPress image's `docker-ensure-installed.sh` helper to populate WordPress core files and `wp-config.php` when needed.

It then checks the database with `wp core is-installed`.

### New WordPress environment

If WordPress is not installed, `wp core install` runs with the configured URL, site title, administrator username, password, and email address.

### Existing WordPress environment

If WordPress is already installed:

- the configured administrator user is created when it does not exist;
- the configured password and email address are applied on every container start;
- the configured user is assigned the `administrator` role.

This startup sequence is idempotent and is intended to work with the persisted WordPress and MariaDB volumes. Changing the administrator password or email address in the active environment file takes effect the next time the WordPress container starts.

These credentials are for local development only.
