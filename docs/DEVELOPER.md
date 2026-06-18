# Developer Guide

This document explains the architecture and conventions of raptus-std-linux for developers who want to understand, maintain, or extend the framework.

## How Bootstrap Works

The installation is a two-stage process. Stage 1 (base system) must complete and reboot before stage 2 (application layer) can run.

```
                         /root/.rslcfg (must exist)
                              │
        bash <(curl -s .../kickstart-standard-linux.sh)
                              │
                    ┌─────────▼──────────┐
                    │  kickstart installs │
                    │  git, clones repo   │
                    │  to /root/scripts/  │
                    │  rsl/               │
                    └─────────┬──────────┘
                              │
              STAGE 1: std-linux/bootstrap.sh
                              │
                 ┌────────────▼─────────────┐
                 │  common.inc (sourced)     │
                 │  ↓                        │
                 │  checkHostname            │
                 │  checkInstall             │
                 │  checkLockFile            │
                 │  ↓                        │
                 │  bootstrap-rocky.sh       │
                 │    ├── repos + packages   │
                 │    ├── environment files  │
                 │    ├── parts/*.inc        │
                 │    ├── services           │
                 │    └── machine detection  │
                 │  ↓                        │
                 │  markAsDone → lockfile    │
                 └────────────┬─────────────┘
                              │
                        *** REBOOT ***
                              │
              STAGE 2: (choose one)
                 ┌────────────┴─────────────┐
                 │                          │
    std-webserver-nginx/        std-upstream-proxy-nginx/
    standard-webserver.sh       standard-webproxy.sh
                 │                          │
         checkBootstrapped           checkBootstrapped
         (requires stage 1)          (requires stage 1)
```

### Execution Guards

Every main script uses guards from `common.inc` to prevent misuse:

| Guard              | Purpose                                              |
|--------------------|------------------------------------------------------|
| `checkInstall`     | Abort if not a supported Linux version                |
| `checkHostname`    | Abort if hostname is not a FQDN                      |
| `checkLockFile`    | Abort if script was already executed (lockfile exists)|
| `checkBootstrapped`| Abort if stage 1 was not completed                   |

Lock files are stored in `/var/rsl/lock/`. To re-run a script, delete its `.done` file.

## Parts and Configs

The framework uses two concepts to configure services: **parts** and **configs**.

### Parts (`parts/*.inc`)

A part is a shell script fragment that gets **sourced** (not executed) by the bootstrap script. It runs in the same shell context, so it has access to all variables from `common.inc` and the parent script.

Parts are sourced **in order** — some depend on packages or config installed by earlier parts. The order in `bootstrap-rocky.sh` is:

```
standard-security.inc      # SSL certs, SELinux, limits.conf
standard-ssh.inc            # SSH key generation
standard-cron.inc           # Cron MAILTO
standard-ntp.inc            # Chrony / timezone
standard-postfix.inc        # Mail relay
standard-snmp.inc           # SNMP monitoring
standard-fstrim.inc         # SSD trim timer
standard-sysdefaults.inc    # dnf-automatic, GRUB, useradd
standard-tuning.inc         # sysctl, network tuning
```

After all parts, a machine-specific part (`machine-$TYPE.inc`) is sourced if it exists, allowing hardware-specific tuning (e.g. `machine-hyperv.inc`).

**How to add a new part:**

1. Create `std-linux/parts/standard-myservice.inc`
2. Add `source $STD_PATH/parts/standard-myservice.inc` in `bootstrap-rocky.sh` at the correct position (consider dependencies)
3. If your part needs config files, add them under `configs/`

### Configs (`configs/`)

Config files are static files that get **copied** to the target system, replacing or supplementing system defaults. They mirror the target filesystem structure:

```
configs/
├── .bashrc                    → /root/.bashrc
├── .screenrc                  → /root/.screenrc
├── .vimrc                     → /root/.vimrc
├── .tmux.conf                 → /root/.tmux.conf
├── etc-postfix/main.cf        → /etc/postfix/main.cf
├── etc-security/limits.conf   → /etc/security/limits.conf
├── etc-snmp/snmpd.conf        → /etc/snmp/snmpd.conf
├── etc-sysctl.d/rsl-defaults.conf → /etc/sysctl.d/rsl-defaults.conf
├── etc-fail2ban/              → /etc/fail2ban/ (manual setup)
└── etc-shorewall/             → /etc/shorewall/ (manual setup)
```

The naming convention is `etc-servicename` (hyphen instead of slash). The part script handles the copy, typically:

```bash
mv /etc/postfix/main.cf /etc/postfix/main.cf.ORIG   # preserve original
cp $STD_PATH/configs/etc-postfix/main.cf /etc/postfix/main.cf
```

Config files may contain **placeholders** that are replaced by `sed` after copying. Common pattern:

```bash
sed -r -i "s/(HOSTMASTER).*$/\1$ADMIN_EMAIL/g" /etc/snmp/snmpd.conf
```

## Module Dependencies

```
common.inc ◄──── shared by everything
     │
     ▼
std-linux (STAGE 1, required)
     │
     ├──► std-webserver-nginx (STAGE 2, option A)
     │        uses: $WEB_PATH, $ROCKY_MAJOR, $HNFULL, $ADMIN_EMAIL
     │        adds: Nginx, PHP-FPM, MariaDB, Memcached
     │        optional (on request): PostgreSQL via util/install-postgresql.sh
     │
     ├──► std-upstream-proxy-nginx (STAGE 2, option B)
     │        uses: $PRX_PATH, $ROCKY_MAJOR, $HNFULL, $ADMIN_EMAIL
     │        adds: Nginx, Memcached (no PHP, no DB)
     │
     └──► std-linux-addons (OPTIONAL, after stage 2)
              standard-certbot.sh   (Let's Encrypt)
              standard-pureftp.sh   (FTP server)
```

**Every module depends on std-linux being completed first.** The stage 2 scripts call `checkBootstrapped` which verifies the lockfile from stage 1. Stage 2 scripts also call `checkLockFile` on themselves — they can only run once.

## Adding a New Module

To add a new application layer module (like a hypothetical `std-mailserver`):

1. Create the directory: `std-mailserver/`
2. Follow the structure: `parts/`, `configs/`, `scripts/`, `templates/`
3. Create a main installer script (e.g. `standard-mailserver.sh`) that:
   - Sources `common.inc`
   - Calls `checkBootstrapped` (ensures stage 1 is done)
   - Calls `checkLockFile` (prevents re-runs)
   - Sources its parts in dependency order
   - Calls `markAsDone` at the end
4. Add its path constant to `common.inc`

## Templates (Webserver/Proxy modules)

Templates are used for per-site configuration (Nginx vhosts, PHP-FPM pools, etc.). They live in `templates/` and use **uppercase placeholder names**:

| Placeholder    | Replaced with           |
|----------------|-------------------------|
| `SITE_NAME`    | Domain name             |
| `UID_NAME`     | Unix user (`s_domain`)  |
| `PHPFPM_PORT`  | Allocated FPM port      |
| `DB_NAME`      | Database name           |
| `DB_USER`      | Database user           |
| `DB_PASS`      | Generated password      |

Substitution uses chained `sed` with intermediate files:

```bash
sed "s/SITE_NAME/$site/g" $TEMPLATE > $CONF.IN.1
sed "s/PHPFPM_PORT/$PORT/g" $CONF.IN.1 > $CONF
rm -f $CONF.IN.*
```

## Version Handling

The variable `$ROCKY_MAJOR` (set in `common.inc`) contains the major OS version (e.g. `"9"` or `"10"`). Use it for:

- Version-specific package names (e.g. `platform-python-devel` vs `python3-devel`)
- Repository URLs: `epel-release-latest-$ROCKY_MAJOR`, `remi-release-$ROCKY_MAJOR`
- Conditional logic: `if test "$ROCKY_MAJOR" = "10"`

## Key Variables (from common.inc)

| Variable          | Source             | Example                          |
|-------------------|--------------------|----------------------------------|
| `$DISTRO`         | Detected           | `rocky`                          |
| `$ROCKY_MAJOR`    | Detected           | `9` or `10`                      |
| `$HNFULL`         | System hostname    | `web01.example.com`              |
| `$ADMIN_EMAIL`    | `/root/.rslcfg`    | `admin@example.com`              |
| `$OUR_IPS`        | `/root/.rslcfg`    | `1.2.3.4,5.6.7.8`               |
| `$OUR_IPS_SPACED` | Derived            | `1.2.3.4 5.6.7.8`               |
| `$ABUSEIPDB_KEY`  | `/root/.rslcfg` or env | AbuseIPDB API key (optional, traffic analysis `--enrich`) |
| `$LOGFILE`        | Generated          | `/var/rsl/log/bootstrap-*.log`   |
| `$LOCKFILE`       | Generated          | `/var/rsl/lock/bootstrap.done`   |
| `$STD_PATH`       | Constant           | `/root/scripts/rsl/std-linux`    |
| `$WEB_PATH`       | Constant           | `/root/scripts/rsl/std-webserver-nginx` |
| `$PRX_PATH`       | Constant           | `/root/scripts/rsl/std-upstream-proxy-nginx` |
| `$PWGENOPTS`      | Constant           | `-B -c -N1 -n 15`               |

## Shell Conventions

- Use `test` for conditionals (not `[` or `[[`)
- Use backticks for command substitution (not `$()`)
- Quote all variable expansions: `"$VAR"`
- Constants in UPPERCASE, locals in lowercase
- Redirect output to logfile: `>> $LOGFILE 2>&1`
- Error messages to stderr: `>> /dev/stderr`
- End every file with `# eof`
