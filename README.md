# raptus-std-linux

Standard Linux server bootstrapper and automation framework by Raptus IT.

Automates the installation and configuration of standardized web hosting infrastructure: Nginx, PHP, MariaDB, PostgreSQL, and supporting services.

## Quick Start

See [docs/OPERATIONS.md](docs/OPERATIONS.md) for the full setup guide. The short version:

```shell
# 1. Set hostname and config
hostnamectl set-hostname hostname.domain.tld
echo "ADMIN_EMAIL=admin@example.com" >> /root/.rslcfg

# 2. Bootstrap
bash <(curl -s https://raw.githubusercontent.com/Raptus/raptus-std-linux/master/kickstart-standard-linux.sh)

# 3. Reboot, then apply security standards
# https://github.com/Raptus/raptus-linux-access

# 4. Install application layer (choose one)
/root/scripts/rsl/std-webserver-nginx/standard-webserver.sh       # Full LEMP stack
/root/scripts/rsl/std-upstream-proxy-nginx/standard-webproxy.sh   # Reverse proxy only
```

## Modules

| Module | Purpose |
|--------|---------|
| `std-linux` | Base system: security, SSH, mail, monitoring, tuning |
| `std-webserver-nginx` | Nginx + PHP-FPM + MariaDB + PostgreSQL + Memcached |
| `std-upstream-proxy-nginx` | Nginx reverse proxy + Memcached |
| `std-linux-addons` | Optional: Pure-FTPd, Certbot/Let's Encrypt |

## Documentation

| Document | Audience |
|----------|----------|
| [docs/OPERATIONS.md](docs/OPERATIONS.md) | Engineers setting up and operating servers |
| [docs/SITE-MANAGEMENT.md](docs/SITE-MANAGEMENT.md) | Site lifecycle: creation, databases, SSL, PHP, deletion |
| [docs/DEVELOPER.md](docs/DEVELOPER.md) | Developers maintaining or extending the framework |
| [CLAUDE.md](CLAUDE.md) | Guidance for Claude Code |
