echo "### Setting up postgresql"
yum -y install postgresql-server postgresql postgresql-libs postgresql-contrib postgis pgtune python-psycopg2 rhdb-utils perl-DBD-Pg perl-DateTime-Format-Pg >> $LOGFILE

/usr/bin/postgresql-setup initdb >> $LOGFILE
systemctl disable postgresql.service >> $LOGFILE 2>&1
systemctl start postgresql.service >> $LOGFILE 2>&1

MPASS="`apg $APGOPTS`"
TFILE="`mktemp -u -t`"
cat > $TFILE << EOF
CREATE ROLE dbadmin WITH SUPERUSER CREATEDB CREATEROLE LOGIN ENCRYPTED PASSWORD '$MPASS';
EOF
sudo -i -u postgres psql -q -f $TFILE template1

rm $TFILE
systemctl stop postgresql.service >> $LOGFILE 2>&1

echo "localhost:5432:*:dbadmin:$MPASS" > /root/.pgpass
chmod u=rw,go= /root/.pgpass

mv /var/lib/pgsql/data/pg_hba.conf /var/lib/pgsql/data/pg_hba.conf.ORIG
echo "local   all         postgres                          ident" >> /var/lib/pgsql/data/pg_hba.conf
echo "local   all         all                               md5" >> /var/lib/pgsql/data/pg_hba.conf
echo "host    all         all         127.0.0.1/32          md5" >> /var/lib/pgsql/data/pg_hba.conf
chown postgres:postgres /var/lib/pgsql/data/pg_hba.conf

passwordInfo "PostgreSQL" "dbadmin" "$MPASS" "localhost:5432"
echo "alias psql=\"psql -h localhost -U dbadmin template1\"" >> /root/.bashrc_local

echo >> /etc/crontab
echo "#30    */1  * * *   root    /root/scripts/rsl/std-webserver-nginx/util/pgsql-dumps.sh" >> /etc/crontab

systemctl disable postgresql >> $LOGFILE 2>&1
