#!/bin/bash

OLDDIR="`pwd`"
cd /root/scripts/rsl
git pull >> /dev/null 
source /root/scripts/rsl/std-linux/common.inc
checkHostname
checkInstall
checkLockFile
checkBootstrapped
touch $LOGFILE
cd $SCRIPTPATH

echo "###"
echo "###"
echo "###"
echo "###"
echo "###"
echo "###"
echo "###"
echo

echo "### Standard setup for webserver"
echo "    Logfile: $LOGFILE"
askConfirmation

# ATTENTION: Dependencies!!!
source $SCRIPTPATH/../std-linux/parts-centos/standard-webserver.inc
source $SCRIPTPATH/../std-linux/parts-centos/standard-memcached.inc
source $SCRIPTPATH/../std-linux/parts-centos/standard-pureftp.inc
source $SCRIPTPATH/../std-linux/parts-centos/standard-mariadb.inc
source $SCRIPTPATH/../std-linux/parts-centos/standard-postgresql.inc
source $SCRIPTPATH/../std-linux/parts-centos/standard-nginx.inc
source $SCRIPTPATH/../std-linux/parts-centos/standard-php.inc
source $SCRIPTPATH/../std-linux/parts-centos/standard-phpmyadmin.inc

echo "### Setting up basic structure"
mkdir -p /home/archived
mkdir -p /home/sites
mkdir -p /home/restricted/{scripts,logs,temp}
chown -R nginx:nginx /home/restricted/logs
chown -R nginx:nginx /home/restricted/temp

echo "### Setting up default site $HNFULL"
$SCRIPTPATH/scripts/create-site.sh $HNFULL default-admin-site
ln -s /home/sites/$HNFULL /home/ADMIN-SITE
admin_site_uid="`stat -c %U /home/sites/$site`"

echo "### Setting up admin area"
cp -Rp $SCRIPTPATH/admin-site/* /home/ADMIN-SITE/pub/httpdocs/

BFS="`apg -a0 -m15 -x15 -d -M NCL`"
sed -i -r "s/INSERT_HERE_GENERATED_BLOWFISH_SECRET/$BFS/g" /home/ADMIN-SITE/pub/httpdocs/admin/phpmyadmin/config.inc.php

DVP="`apg $APGOPTS`"
htpasswd /home/sites/$HNFULL/auth/htpasswd admin $DVP
passwordInfo "Default site" "admin" "$DVP" "https://$HNFULL/admin"

echo "### Finishing installation"
echo "alias logtail=\"cd /var/log ; tail -f cron dmesg maillog messages secure nginx/error.log mysqld.log pureftpd.log /home/sites/*/pub/log/*.log\"" >> /root/.bashrc_local

$SCRIPTPATH/scripts/manage-site.sh $HNFULL site-enable >> $LOGFILE
$SCRIPTPATH/scripts/web/manage-site.sh $HNFULL php-enable >> $LOGFILE
$SCRIPTPATH/scripts/web/update-static.sh >> $LOGFILE

echo ""
echo "    ATTENTION"
echo "    Did you read and consider the installation notes?"
echo "    You should really, really TEST and FINETUNE this installation."
echo

markAsDone
cd $OLDDIR

# eof