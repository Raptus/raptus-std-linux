echo "### Setting up postgresql (disabled per default)"
dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm >> $LOGFILE 2>&1
# Disable the built-in PostgreSQL module (AppStream)
dnf -y module disable postgresql
dnf -y install postgresql12-server postgresql12 postgresql12-libs postgresql12-contrib \
               postgis30_12 python3-psycopg2 perl-DBD-Pg >> $LOGFILE 2>&1

/usr/pgsql-12/bin/postgresql-12-setup initdb >> $LOGFILE
systemctl disable postgresql-12.service >> $LOGFILE 2>&1
systemctl start postgresql-12.service >> $LOGFILE 2>&1

MPASS="`pwgen $PWGENOPTS`"
TFILE="`mktemp -u -t`"
cat > $TFILE << EOF
CREATE ROLE dbadmin WITH SUPERUSER CREATEDB CREATEROLE LOGIN ENCRYPTED PASSWORD '$MPASS';
EOF
sudo -i -u postgres psql -q -f $TFILE template1

rm $TFILE
systemctl stop postgresql-12.service >> $LOGFILE 2>&1

echo "localhost:5432:*:dbadmin:$MPASS" > /root/.pgpass
chmod u=rw,go= /root/.pgpass

mv /var/lib/pgsql/12/data/pg_hba.conf /var/lib/pgsql/12/data/pg_hba.conf.ORIG
echo "local   all         postgres                          ident" >> /var/lib/pgsql/12/data/pg_hba.conf
echo "local   all         all                               md5" >> /var/lib/pgsql/12/data/pg_hba.conf
echo "host    all         all         127.0.0.1/32          md5" >> /var/lib/pgsql/12/data/pg_hba.conf
chown postgres:postgres /var/lib/pgsql/12/data/pg_hba.conf

passwordInfo "PostgreSQL" "dbadmin" "$MPASS" "localhost:5432"
echo "alias psql=\"psql -h localhost -U dbadmin template1\"" >> /root/.bashrc_local

echo >> /etc/crontab
echo "#30    */1  * * *   root    /root/scripts/rsl/std-webserver-nginx/util/pgsql-dumps.sh" >> /etc/crontab

systemctl disable postgresql-12 >> $LOGFILE 2>&1
