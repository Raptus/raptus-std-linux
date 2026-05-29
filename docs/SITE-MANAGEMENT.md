# Site Management Reference

This document covers the complete lifecycle of a hosted site — from creation through operation to deletion.

## Site Creation

### Command

```shell
/root/scripts/rsl/std-webserver-nginx/scripts/create-site.sh <domain> <template>
```

### Templates

| Template | Use case |
|----------|----------|
| `std-ssl` | Standard HTTPS site with PHP |
| `wordpress-ssl` | WordPress with caching and SEO configs |
| `zope-ssl` | Reverse proxy for Zope/Plone |
| `default-admin-site` | Admin interface (only one per server) |

### What create-site.sh does

1. **Creates a Unix account** named `s_<domain>` in the `nginx` group (shell: `/bin/false`). If the name exceeds 32 characters, it is shortened to `s_<first15chars>_<uuid>`.

2. **Creates the directory structure:**
   ```
   /home/sites/<domain>/
   ├── auth/              htpasswd files
   ├── cache/             Application cache (writable by PHP)
   ├── conf/              Configuration
   │   ├── nginx.conf     Nginx vhost config
   │   ├── nginx-rewrites.conf   SEO rewrites (editable)
   │   ├── php-cli/        PHP CLI config + version symlink
   │   └── php-fpm/        PHP-FPM pool config + version symlink
   ├── pub/
   │   ├── httpdocs/       Document root
   │   ├── log/            Nginx and PHP logs (writable)
   │   ├── sessions/       PHP session storage
   │   ├── scripts/        Site-specific scripts
   │   └── tmp/fcgi/       FastCGI temp files
   ├── run/                PHP-FPM unix socket
   ├── scripts/            Admin scripts (composer.sh, php-cli.sh, php-fpm.sh)
   └── ssl/                Symlinks to SSL certificates
   ```

3. **Allocates a port range** (10 ports starting from 10010, tracked in `/var/rsl/state/last-port-offset`). In practice, PHP-FPM uses a unix socket at `run/php-fpm.sock`.

4. **Generates Nginx config** from the selected template with `SITE_NAME` and `PHPFPM_PORT` substituted.

5. **Generates PHP-FPM config** — systemd unit, pool config, CLI/FPM wrappers, php.ini files.

6. **Sets permissions** via `reset-access-rights.sh`.

7. **Outputs instructions** for enabling the site.

### After Creation

The site is created but not yet active. Enable it:

```shell
/root/scripts/rsl/std-webserver-nginx/scripts/manage-site.sh <domain> site-enable
/root/scripts/rsl/std-webserver-nginx/scripts/manage-site.sh <domain> php-enable
```

## Site Actions

### Command

```shell
/root/scripts/rsl/std-webserver-nginx/scripts/manage-site.sh <domain> <action>
```

### Available Actions

#### site-enable

Symlinks the site's Nginx config to `/etc/nginx/sites-enabled/` and reloads Nginx.

#### site-disable

Removes the Nginx symlink, reloads Nginx, and also disables the PHP-FPM pool.

#### site-delete

Deletes the site completely (with confirmation prompt):
- Removes all FTP accounts associated with the site
- Deletes `/home/sites/<domain>/` and all contents
- Deletes the Unix account
- Removes the PHP-FPM systemd unit

**Databases are NOT deleted** — this must be done manually.

#### site-archive

Creates a tarball at `/home/archived/<domain>-<YYYYMMDD>.tar.gz`, then performs `site-delete`.

#### php-enable

Enables and starts the PHP-FPM systemd service `php-fpm_<domain>.service`.

#### php-disable

Stops and disables the PHP-FPM service.

#### php-set &lt;version&gt;

Switches the site to a different PHP version (e.g. `php-set php84`):
- Installs the PHP version if not already present
- Updates the version symlinks in `conf/php-cli/php` and `conf/php-fpm/php`
- Updates the `composer.sh` wrapper

After switching, the FPM pool must be stopped and started (restart is not sufficient):
```shell
systemctl stop php-fpm_<domain>.service
systemctl start php-fpm_<domain>.service
```

#### php-enable-nginx-pool

Adds a second PHP-FPM pool running as the `nginx` user (instead of the site owner). Useful when Nginx needs to execute PHP directly (e.g. phpMyAdmin on the admin site).

## Database Management

### Create a MariaDB Database

```shell
/root/scripts/rsl/std-webserver-nginx/scripts/create-mariadb-db.sh <db_name> <db_user>
```

- Username max 16 characters
- Generates a random password
- Creates the database and a dedicated user with full privileges on that database only
- Credentials stored in `/root/generated-passwords.txt`

Admin access: `mysql` (uses credentials from `/root/.my.cnf`)

### Create a PostgreSQL Database

PostgreSQL is not installed by the standard webserver setup. Install it on request first:

```shell
/root/scripts/rsl/std-webserver-nginx/util/install-postgresql.sh
```

Then create databases:

```shell
/root/scripts/rsl/std-webserver-nginx/scripts/create-pgsql-db.sh <db_name> <db_user>
```

- Starts PostgreSQL if not already running
- Same credential handling as MariaDB

Admin access: `psql` (alias configured to use dbadmin user)

## SSL Certificates

### Self-Signed (Default)

Created automatically during bootstrap. Symlinked into every site at:
- `ssl/package.pem` → self-signed certificate
- `ssl/private.key` → private key

### Let's Encrypt

```shell
/root/scripts/rsl/std-webserver-nginx/scripts/ssl-letsencrypt-certificate.sh <domain>
```

This script:
1. Requests a certificate via certbot
2. Replaces the SSL symlinks to point to the Let's Encrypt certificate
3. Tests the Nginx config
4. Reloads Nginx
5. Adds a daily certbot renewal cron job (if not already present)

**Prerequisites:**
- Certbot must be installed (`std-linux-addons/standard-certbot.sh`)
- `ADMIN_EMAIL` must be set in `/root/.rslcfg` (used as ACME account)

## HTTP BasicAuth

```shell
/root/scripts/rsl/std-webserver-nginx/scripts/create-http-account.sh <domain> <username>
```

Generates a password and adds the user to `/home/sites/<domain>/auth/htpasswd`.

## FTP Accounts

```shell
/root/scripts/rsl/std-webserver-nginx/scripts/create-ftp-account.sh <domain> <username>
```

- Requires Pure-FTPd addon to be installed
- FTP root is restricted to `/home/sites/<domain>/pub/`
- One FTP account per site
- Starts Pure-FTPd if not already running

## Permission Model

Permissions are set by `reset-access-rights.sh` and follow this policy:

| Directory | Owner | Permissions | Purpose |
|-----------|-------|-------------|---------|
| Site root | `s_<domain>:nginx` | PHP writes, Nginx reads | Application files |
| `cache/`, `run/`, `pub/tmp/`, `pub/log/` | `s_<domain>:nginx` | Both write | Runtime data |
| `auth/`, `conf/`, `ssl/` | `root:root` | Read-only for PHP/Nginx | Security-sensitive config |
| `scripts/` | `root:root` | Execute for all | Admin scripts |
| `pub/scripts/` | `s_<domain>:nginx` | Owner executes | Site-specific scripts |
| `.ssh/` | `s_<domain>` | Owner only | SSH keys |

To repair permissions:
```shell
# Single site
/root/scripts/rsl/std-webserver-nginx/scripts/reset-access-rights.sh <domain>

# All sites (interactive)
/root/scripts/rsl/std-webserver-nginx/scripts/reset-access-rights.sh
```

## Nginx Configuration

### Site Config Location

- Template-generated: `/home/sites/<domain>/conf/nginx.conf`
- Enabled symlink: `/etc/nginx/sites-enabled/<domain>.conf`
- Custom rewrites: `/home/sites/<domain>/conf/nginx-rewrites.conf`

### Key Nginx Features per Site

- HTTP → HTTPS redirect
- PHP via unix socket (`run/php-fpm.sock`)
- Static file caching (1 day for images, CSS, JS)
- Dotfile and temp file denial
- ACME challenge passthrough for certbot
- Optional: HTTP BasicAuth, maintenance mode, custom error pages (see template comments)

### Reload After Changes

```shell
/root/scripts/rsl/std-webserver-nginx/scripts/update-static.sh
```

Or directly:
```shell
nginx -t && systemctl reload nginx
```
