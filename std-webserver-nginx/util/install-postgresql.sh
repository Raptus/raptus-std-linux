#!/bin/bash

source /root/scripts/rsl/common.inc

# PostgreSQL is installed on request only, not during the standard webserver
# setup. Run this script manually to add PostgreSQL to a webserver.

# Major version comes from common.inc (DEFAULT_PGSQL).
PGVER="$DEFAULT_PGSQL"

PGBIN="/usr/pgsql-$PGVER/bin"
PGDATA="/var/lib/pgsql/$PGVER/data"
PGSVC="postgresql-$PGVER"

if test -d "/usr/pgsql-$PGVER"
then
    echo "PostgreSQL $PGVER appears to be already installed (/usr/pgsql-$PGVER exists)."
    echo "Aborting to avoid reinitializing the cluster."
    exit 1
fi

echo "### Setting up postgresql $PGVER (installed on request, service disabled per default)"

# crb is required for some PostgreSQL dependencies
dnf -y config-manager --set-enabled crb >> $LOGFILE 2>&1

dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-$ROCKY_MAJOR-x86_64/pgdg-redhat-repo-latest.noarch.rpm >> $LOGFILE 2>&1
# Disable the built-in PostgreSQL module (not needed on Rocky 10, modularity removed)
if test "$ROCKY_MAJOR" = "9"
then
    dnf -y module disable postgresql >> $LOGFILE 2>&1
fi
dnf -y install postgresql$PGVER-server postgresql$PGVER postgresql$PGVER-libs postgresql$PGVER-contrib \
               python3-psycopg2 perl-DBD-Pg >> $LOGFILE 2>&1

$PGBIN/postgresql-$PGVER-setup initdb >> $LOGFILE
systemctl disable $PGSVC.service >> $LOGFILE 2>&1
systemctl start $PGSVC.service >> $LOGFILE 2>&1

MPASS="`pwgen $PWGENOPTS`"
TFILE="`mktemp -u -t`"
cat > $TFILE << EOF
CREATE ROLE dbadmin WITH SUPERUSER CREATEDB CREATEROLE LOGIN ENCRYPTED PASSWORD '$MPASS';
EOF
sudo -i -u postgres psql -q -f $TFILE template1

rm $TFILE
systemctl stop $PGSVC.service >> $LOGFILE 2>&1

echo "localhost:5432:*:dbadmin:$MPASS" > /root/.pgpass
chmod u=rw,go= /root/.pgpass

mv $PGDATA/pg_hba.conf $PGDATA/pg_hba.conf.ORIG
echo "local   all         postgres                          ident" >> $PGDATA/pg_hba.conf
echo "local   all         all                               md5" >> $PGDATA/pg_hba.conf
echo "host    all         all         127.0.0.1/32          md5" >> $PGDATA/pg_hba.conf
chown postgres:postgres $PGDATA/pg_hba.conf

passwordInfo "PostgreSQL" "dbadmin" "$MPASS" "localhost:5432"
echo "alias psql=\"psql -h localhost -U dbadmin template1\"" >> /root/.bashrc_local

# Enable hourly dumps now that PostgreSQL is installed. The dump script itself
# still no-ops while the service is inactive.
echo >> /etc/crontab
echo "30    */1  * * *   root    /root/scripts/rsl/std-webserver-nginx/util/pgsql-dumps.sh" >> /etc/crontab

systemctl disable $PGSVC >> $LOGFILE 2>&1

# eof
