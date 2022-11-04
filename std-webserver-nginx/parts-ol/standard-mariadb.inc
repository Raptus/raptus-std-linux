echo "### Setting up mariadb"

rm /etc/my.cnf.d/*
cp $WEB_PATH/configs-ol/etc-mariadb/* /etc/my.cnf.d/
mkdir -p /var/log/mysql

dnf -y install mariadb-devel mariadb-server >> $LOGFILE 2>&1

rm /etc/my.cnf.d/*.rpm*
cp $WEB_PATH/configs-ol/etc-mariadb/* /etc/my.cnf.d/
chown mysql:mysql /var/log/mysql

systemctl enable mariadb.service >> $LOGFILE 2>&1
systemctl start mariadb.service >> $LOGFILE 2>&1

MPASS="`pwgen $PWGENOPTS`"
TFILE="`mktemp -u -t`"
cat > $TFILE << EOF
use mysql;
delete from user where host != 'localhost' and host != '127.0.0.1';
delete from user where user='';
rename user 'root'@'localhost' to 'dbadmin'@'localhost';
set password for 'dbadmin'@localhost = PASSWORD($MPASS);
flush privileges;
EOF

mysql -h localhost -u root < $TFILE
rm $TFILE

cat > /root/.my.cnf << EOF
[client]
user=dbadmin
password=$MPASS
EOF
chmod u=+rw,go= /root/.my.cnf

passwordInfo "MySQL" "dbadmin" "$MPASS" "localhost:3306"

echo >> /etc/crontab
echo "00    4    * * *   root    /root/scripts/rsl/std-webserver-nginx/util/mariadb-maintenance.sh" >> /etc/crontab
echo "00    */1  * * *   root    /root/scripts/rsl/std-webserver-nginx/util/mariadb-dumps.sh" >> /etc/crontab
