echo "### Setting up mariadb"

REPONAME="mariadb102"
MARIADBVER="10.2"

cat > /etc/yum.repos.d/$REPONAME.repo << EOF
[$REPONAME]
name = MariaDB
baseurl = http://yum.mariadb.org/$MARIADBVER/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
enabled=0
gpgcheck=1
EOF

#
# THE REPO IS DISABLED BY DEFAULT, BECAUSE WE DO NOT WANT "yum update" TO INCLUDE ADDITIONAL PACKETS
# IN ORDER TO ENABLE THE REPO USE THIS (AT YOUR OWN RISK):   yum-config-manager --enable <name of repository>
#

mv /etc/my.cnf.d /etc/my.cnf.d.ORIG
mkdir -p /etc/my.cnf.d
cp $WEB_PATH/configs-centos/etc-mariadb/* /etc/my.cnf.d/
mkdir -p /var/log/mysql
yum -y --enablerepo=$REPONAME install MariaDB-shared >> $LOGFILE 2>&1
yum -y --enablerepo=$REPONAME install MariaDB-devel >> $LOGFILE 2>&1
yum -y --enablerepo=$REPONAME install MariaDB-client >> $LOGFILE 2>&1
yum -y --enablerepo=$REPONAME install MariaDB-server >> $LOGFILE 2>&1
yum -y install mytop innotop mysqltuner >> $LOGFILE
chown mysql:mysql /var/log/mysql

systemctl enable mariadb.service >> $LOGFILE 2>&1
systemctl start mariadb.service >> $LOGFILE 2>&1

MPASS="`apg $APGOPTS`"
TFILE="`mktemp -u -t`"
cat > $TFILE << EOF
use mysql;
delete from user where host != 'localhost' and host != '127.0.0.1';
delete from user where user='';
update user set User='dbadmin' where User='root';
update user set password=PASSWORD('$MPASS') where User='dbadmin';
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
