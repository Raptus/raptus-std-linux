# Operations Runbook

This document is a reference for engineers setting up and operating servers provisioned with raptus-std-linux.

## Initial Server Setup

### Prerequisites

- Linux VM with a supported distribution (e.g. Azure Marketplace: Rocky Linux for x86_64)
- Non-LVM partition layout (XFS is flexible enough)
- Disk resized to target size

### Step 1: Prepare the System

Resize partition and filesystem:
```shell
growpart /dev/nvme0n1 4
xfs_growfs /dev/nvme0n1p4
```

Set up swap (adjust size as needed):
```shell
touch /var/lib/cloud/scripts/per-boot/create_swapfile.sh
chmod +x /var/lib/cloud/scripts/per-boot/create_swapfile.sh

cat > /var/lib/cloud/scripts/per-boot/create_swapfile.sh << EOF
#!/bin/sh
if [ ! -f '/var/swapfile' ]; then
fallocate --length 4GiB /var/swapfile
chmod 600 /var/swapfile
mkswap /var/swapfile
swapon /var/swapfile
swapon -a
else
swapon /var/swapfile; fi
EOF
```

### Step 2: Configure

Set hostname (must be a FQDN):
```shell
hostnamectl set-hostname hostname.domain.tld
```

Create configuration file:
```shell
echo "ADMIN_EMAIL=admin@example.com" >> /root/.rslcfg
```

Optional settings in `/root/.rslcfg`:
```
OUR_IPS=1.2.3.4,5.6.7.8      # Management IPs (comma-separated, used for admin site ACLs)
ENABLE_FIREWALL=1              # Enable Shorewall firewall
```

### Step 3: Bootstrap

```shell
bash <(curl -s https://raw.githubusercontent.com/Raptus/raptus-std-linux/master/kickstart-standard-linux.sh)
```

This installs base packages, configures security, SSH, mail, monitoring, and system tuning. **Reboot after completion.**

### Step 4: Security Hardening

Apply Raptus security standards:
```shell
# Follow instructions at https://github.com/Raptus/raptus-linux-access
```

### Step 5: Application Layer

Choose one:

**Webserver** (Nginx + PHP + MariaDB + Memcached):
```shell
/root/scripts/rsl/std-webserver-nginx/standard-webserver.sh
```

**Upstream Proxy** (Nginx + Memcached only):
```shell
/root/scripts/rsl/std-upstream-proxy-nginx/standard-webproxy.sh
```

**Optional: PostgreSQL** — not installed by the webserver setup. Install on request:
```shell
/root/scripts/rsl/std-webserver-nginx/util/install-postgresql.sh
```
This installs PostgreSQL (service disabled by default) and enables the hourly dump cron. The major version is set via `DEFAULT_PGSQL` in `common.inc`. PostGIS is not installed by default.

### Optional Addons

```shell
# FTP server (Pure-FTPd)
/root/scripts/rsl/std-linux-addons/standard-pureftp.sh

# Certbot for Let's Encrypt
/root/scripts/rsl/std-linux-addons/standard-certbot.sh
```

## Day-to-Day Operations

All scripts are located at `/root/scripts/rsl/`. The examples below use the webserver module. For the proxy module, replace `std-webserver-nginx` with `std-upstream-proxy-nginx`.

### Creating a Site

```shell
/root/scripts/rsl/std-webserver-nginx/scripts/create-site.sh example.com std-ssl
```

Available templates:
- `std-ssl` — standard HTTPS site
- `wordpress-ssl` — WordPress-optimized with caching configs
- `zope-ssl` — Zope/Plone reverse proxy
- `default-admin-site` — admin interface (created automatically during setup)

After creation, enable the site and PHP:
```shell
/root/scripts/rsl/std-webserver-nginx/scripts/manage-site.sh example.com site-enable
/root/scripts/rsl/std-webserver-nginx/scripts/manage-site.sh example.com php-enable
```

### Creating a Database

**MariaDB:**
```shell
/root/scripts/rsl/std-webserver-nginx/scripts/create-mariadb-db.sh mydb mydbuser
```

**PostgreSQL:** (requires `util/install-postgresql.sh` to have been run first)
```shell
/root/scripts/rsl/std-webserver-nginx/scripts/create-pgsql-db.sh mydb mydbuser
```

Both scripts generate a random password and store it in `/root/generated-passwords.txt`.

### SSL Certificates (Let's Encrypt)

Requires certbot addon to be installed first.

```shell
/root/scripts/rsl/std-webserver-nginx/scripts/ssl-letsencrypt-certificate.sh example.com
```

This creates the certificate, updates the SSL symlinks, and adds a daily renewal cron job.

### Creating User Accounts

**HTTP BasicAuth** (for site access restriction):
```shell
/root/scripts/rsl/std-webserver-nginx/scripts/create-http-account.sh example.com myuser
```

**FTP** (requires Pure-FTPd addon):
```shell
/root/scripts/rsl/std-webserver-nginx/scripts/create-ftp-account.sh example.com myftpuser
```

### Managing Sites

```shell
MANAGE="/root/scripts/rsl/std-webserver-nginx/scripts/manage-site.sh"

$MANAGE example.com site-enable          # Enable Nginx config
$MANAGE example.com site-disable         # Disable site and PHP
$MANAGE example.com site-delete          # Delete site (keeps databases!)
$MANAGE example.com site-archive         # Archive to tarball, then delete

$MANAGE example.com php-enable           # Start PHP-FPM pool
$MANAGE example.com php-disable          # Stop PHP-FPM pool
$MANAGE example.com php-set php84        # Switch to a given PHP version
$MANAGE example.com php-enable-nginx-pool  # Add separate FPM pool as nginx user
```

After switching PHP versions, the FPM pool must be stopped and started (not restarted):
```shell
systemctl stop php-fpm_example.com.service
systemctl start php-fpm_example.com.service
```

### Installing Additional PHP Versions

```shell
/root/scripts/rsl/std-webserver-nginx/util/install-php.sh php83
```

Then switch individual sites using `manage-site.sh`.

### Fixing Permissions

For a single site:
```shell
/root/scripts/rsl/std-webserver-nginx/scripts/reset-access-rights.sh example.com
```

For all sites (interactive confirmation):
```shell
/root/scripts/rsl/std-webserver-nginx/scripts/reset-access-rights.sh
```

## Backups

### MariaDB

Automated hourly dumps via cron to `/home/backups/mariadb/`. Each database gets a separate gzipped dump file named by hour (`mysql_dbname_dump_04h.mysql.gz`). This gives 24 rotating hourly snapshots.

### PostgreSQL

Automated hourly dumps via cron to `/home/backups/pgsql/`. The cron entry is added by `util/install-postgresql.sh`, so dumps only exist once PostgreSQL has been installed. The dump script auto-detects the installed PostgreSQL version and no-ops while its service is inactive.

### Database Maintenance

MariaDB maintenance runs daily at 04:00:
- **First Sunday of the month**: full `--optimize` on all databases
- **All other days**: `--check-only-changed`

Log: `/var/log/mariadb-maintenance.log`

## Generated Passwords

All auto-generated passwords are written to `/root/generated-passwords.txt` (mode 600).

**Important:** After setup, document all passwords in the Raptus password vault, then delete the file from the server:
```shell
rm /root/generated-passwords.txt
```

## Useful Aliases

After installation, the following alias is available:
```shell
logtail    # Tails all important log files (nginx, mail, cron, php, etc.)
```

## Key Paths on the Server

| Path | Purpose |
|------|---------|
| `/root/scripts/rsl/` | This repository |
| `/root/.rslcfg` | Server configuration |
| `/root/generated-passwords.txt` | Generated credentials |
| `/root/.my.cnf` | MariaDB admin credentials |
| `/root/.pgpass` | PostgreSQL admin credentials |
| `/home/sites/` | All hosted sites |
| `/home/sites/{domain}/pub/httpdocs/` | Document root |
| `/home/sites/{domain}/pub/log/` | Site-specific logs |
| `/home/sites/{domain}/conf/` | Site-specific config |
| `/home/sites/{domain}/ssl/` | SSL certificate symlinks |
| `/home/backups/` | Database dumps |
| `/var/rsl/log/` | Script execution logs |
| `/var/rsl/lock/` | Execution lock files |
