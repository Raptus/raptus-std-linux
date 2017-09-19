#!/bin/bash

OLDDIR="`pwd`"
cd /root/scripts/rsl
git pull >> /dev/null 
source /root/scripts/rsl/common.inc
checkHostname
checkInstall
checkLockFile
checkBootstrapped
touch $LOGFILE
cd $WEB_PATH

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
source $WEB_PATH/parts-centos/standard-webserver.inc
source $WEB_PATH/parts-centos/standard-memcached.inc
source $WEB_PATH/parts-centos/standard-pureftp.inc
source $WEB_PATH/parts-centos/standard-mariadb.inc
source $WEB_PATH/parts-centos/standard-postgresql.inc
source $WEB_PATH/parts-centos/standard-nginx.inc
source $WEB_PATH/parts-centos/standard-php.inc
source $WEB_PATH/parts-centos/standard-phpmyadmin.inc

echo "### Setting up basic structure"
mkdir -p /home/archived
mkdir -p /home/sites
mkdir -p /home/restricted/{scripts,logs,temp}
chown -R nginx:nginx /home/restricted/logs
chown -R nginx:nginx /home/restricted/temp

echo "### Setting up default/admin site $HNFULL"
$WEB_PATH/scripts/create-site.sh $HNFULL default-admin-site
$WEB_PATH/scripts/manage-site.sh $HNFULL site-enable >> $LOGFILE
$WEB_PATH/scripts/web/manage-site.sh $HNFULL php-enable >> $LOGFILE
$WEB_PATH/scripts/web/update-static.sh >> $LOGFILE

ln -s /home/sites/$HNFULL /home/ADMIN-SITE
admin_site_uid="`stat -c %U /home/sites/$site`"
cp -Rp $WEB_PATH/admin-site/* /home/ADMIN-SITE/pub/httpdocs/
DVP="`apg $APGOPTS`"
htpasswd /home/sites/$HNFULL/auth/htpasswd admin $DVP
passwordInfo "Default site" "admin" "$DVP" "https://$HNFULL/admin"

echo "### Finishing installation"
echo "alias logtail=\"cd /var/log ; tail -f cron dmesg maillog messages secure nginx/error.log mysqld.log pureftpd.log /home/sites/*/pub/log/*.log\"" >> /root/.bashrc_local

echo ""
echo "    ATTENTION"
echo "    Did you read and consider the installation notes?"
echo "    You should really, really TEST and FINETUNE this installation."
echo

markAsDone
cd $OLDDIR

# eof