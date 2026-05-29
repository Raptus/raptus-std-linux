# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**raptus-std-linux** is a server bootstrapping and automation framework maintained by Raptus IT. It automates the installation and configuration of standardized web hosting infrastructure: Nginx, PHP (FPM), MariaDB, PostgreSQL, Memcached, and supporting services.

The repo is deployed to `/root/scripts/rsl` on target servers via `kickstart-standard-linux.sh`. All scripts run as root.

## Architecture

### Two-Stage Bootstrap

1. **Base system** (`std-linux/bootstrap.sh` → `bootstrap-rocky.sh`): Installs packages, configures security (SSH, Fail2Ban, Shorewall), mail (Postfix), monitoring (SNMP), and system tuning. Requires a reboot after completion.
2. **Application layer** (choose one):
   - `std-webserver-nginx/standard-webserver.sh` — LEMP stack (Nginx + PHP + MariaDB + Memcached). PostgreSQL is **not** installed here; install it on request via `std-webserver-nginx/util/install-postgresql.sh`.
   - `std-upstream-proxy-nginx/standard-webproxy.sh` — reverse proxy only (Nginx + Memcached, no PHP/DB)
3. **Optional addons** (`std-linux-addons/`): Pure-FTPd, Certbot/Let's Encrypt

### Module Layout

Each module (`std-linux`, `std-webserver-nginx`, `std-upstream-proxy-nginx`) follows the same structure:

- `parts/` — sourced `.inc` files, each configuring one service (executed sequentially)
- `configs/` — files copied verbatim to the target system (mirroring `/etc/` paths)
- `scripts/` — operational scripts (site creation, DB creation, SSL, etc.)
- `templates/` — config templates with placeholder variables
- `util/` — maintenance and helper scripts

`common.inc` at the repo root provides shared functions and path constants used by all modules.

### Path Constants (defined in common.inc)

| Variable   | Path                                      |
|------------|-------------------------------------------|
| `RSL_PATH` | `/root/scripts/rsl`                       |
| `STD_PATH` | `/root/scripts/rsl/std-linux`             |
| `ADN_PATH` | `/root/scripts/rsl/std-linux-addons`      |
| `WEB_PATH` | `/root/scripts/rsl/std-webserver-nginx`   |
| `PRX_PATH` | `/root/scripts/rsl/std-upstream-proxy-nginx` |

### Runtime State on Target Servers

| Path                          | Purpose                              |
|-------------------------------|--------------------------------------|
| `/root/.rslcfg`               | Master config (ADMIN_EMAIL, OUR_IPS, ENABLE_FIREWALL) |
| `/root/generated-passwords.txt` | Generated credentials (mode 600)   |
| `/var/rsl/lock/*.done`        | Execution lock files (prevent re-runs) |
| `/var/rsl/log/`               | Timestamped execution logs           |
| `/var/rsl/state/`             | Persistent state (e.g. `last-port-offset`) |

## Site Management

### Site Directory Structure

Each site lives at `/home/sites/{domain}/` with a dedicated unix user `s_{domain}` in the `nginx` group:

```
/home/sites/{domain}/
├── auth/          # htpasswd files
├── cache/         # Application cache
├── conf/          # nginx.conf, php-cli/, php-fpm/
├── pub/
│   ├── httpdocs/  # Document root
│   ├── log/       # Nginx/PHP logs
│   ├── sessions/  # PHP sessions
│   └── tmp/fcgi/  # FastCGI temp
├── run/           # PHP-FPM unix sockets
├── scripts/       # Site admin scripts
└── ssl/           # SSL certs (symlinked)
```

### Port Allocation

PHP-FPM ports are allocated sequentially from base `10010` in blocks of 10 (10010–10019, 10020–10029, ...). The current offset is tracked in `/var/rsl/state/last-port-offset`. In practice, unix sockets at `run/php-fpm.sock` are used instead of TCP ports.

### Key Operational Scripts

- `scripts/create-site.sh <domain> <template>` — creates user, directories, nginx/PHP-FPM config from template, SSL symlinks
- `scripts/manage-site.sh <domain> <action>` — enable/disable/delete/archive sites, switch PHP versions
- `scripts/create-mariadb-db.sh` / `create-pgsql-db.sh` — create databases with dedicated users
- `scripts/ssl-letsencrypt-certificate.sh` — automate Let's Encrypt certificates
- `scripts/reset-access-rights.sh <domain>` — repair file ownership and permissions

## Shell Scripting Conventions

**Follow these patterns when modifying or adding scripts:**

- Shebang: `#!/bin/bash`
- Source common.inc: `source /root/scripts/rsl/common.inc`
- End every file with `# eof`
- Use `test` for conditionals (not `[` or `[[`): `test -f "$FILE"`, `test -z "$VAR"`
- Use backticks for command substitution: `` DISTRO="`grep ...`" `` (not `$()`)
- Constants/config vars in UPPERCASE: `ADMIN_EMAIL`, `HNFULL`, `LOGFILE`
- Local/temp vars in lowercase: `site`, `uid`, `dbpass`
- Quote all variable expansions: `"$VAR"`
- Redirect output to logfile: `>> $LOGFILE 2>&1`
- Error messages to stderr: `>> /dev/stderr`
- Password generation: `` `pwgen $PWGENOPTS` `` (15 chars, no ambiguous)
- Lock file pattern: call `checkLockFile` to prevent duplicate execution
- Save/restore working directory: `` OLDDIR="`pwd`" `` ... `cd $OLDDIR`

### Template Variable Substitution

Templates use plain uppercase placeholder names (`SITE_NAME`, `UID_NAME`, `PHPFPM_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS`) replaced via chained `sed`:

```bash
sed "s/SITE_NAME/$site/g" $TEMPLATE > $CONFDIR/nginx.conf.IN.1
sed "s/PHPFPM_PORT/$PORT/g" $CONFDIR/nginx.conf.IN.1 > $CONFDIR/nginx.conf
rm -f $CONFDIR/nginx.conf.IN.*
```

Intermediate files use `.IN.1`, `.IN.2` suffixes and are cleaned up after the chain.

### Config File Installation

- Copy directory trees: `cp -R $WEB_PATH/configs/etc-nginx/* /etc/nginx/`
- Preserve originals: `mv /etc/nginx /etc/nginx.ORIG`
- Package installation: `dnf -y install pkg1 pkg2 >> $LOGFILE 2>&1`
