#!/bin/bash

OLDDIR="`pwd`"
cd /root/scripts/rsl
git config pull.rebase false
git pull >> /dev/null
source /root/scripts/rsl/common.inc
checkHostname
checkInstall
checkLockFile
checkBootstrapped
touch $LOGFILE
cd $WEB_PATH

echo "### Initializing package repositories"
dnf -y config-manager --set-enabled ol9_codeready_builder  >> $LOGFILE 2>&1
dnf -y clean all >> $LOGFILE 2>&1

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

echo "### Setting up basic structure"
mkdir -p /home/archived
mkdir -p /home/sites
mkdir -p /home/restricted/{scripts,logs,temp}

# ATTENTION: Dependencies!!!
source $WEB_PATH/parts/standard-webserver.inc
source $WEB_PATH/parts/standard-memcached.inc
source $WEB_PATH/parts/standard-postgresql.inc
source $WEB_PATH/parts/standard-mariadb.inc
source $WEB_PATH/parts/standard-nginx.inc
source $WEB_PATH/parts/standard-php.inc

echo "### Setting up default/admin site $HNFULL"
$WEB_PATH/scripts/create-site.sh $HNFULL default-admin-site >> $LOGFILE 2>&1
admin_site_uid="`stat -c %U /home/sites/$site`"
cp -Rp $WEB_PATH/admin-site/* /home/ADMIN-SITE/pub/httpdocs/
DVP="`pwgen $PWGENOPTS`"

htpasswd /home/sites/$HNFULL/auth/htpasswd admin $DVP
passwordInfo "Default site" "admin" "$DVP" "https://$HNFULL/admin"
$WEB_PATH/scripts/manage-site.sh $HNFULL site-enable >> $LOGFILE 2>&1
$WEB_PATH/scripts/manage-site.sh $HNFULL php-enable >> $LOGFILE 2>&1

echo "### Setting up phpMyAdmin"
$phpvers /opt/$phpvers/opt/composer/bin/composer.phar --quiet --no-interaction create-project phpmyadmin/phpmyadmin /home/sites/$HNFULL/pub/httpdocs/admin/phpmyadmin/ >> $LOGFILE 2>&1
cp $WEB_PATH/configs/phpmyadmin/config.inc.php /home/sites/$HNFULL/pub/httpdocs/admin/phpmyadmin/
BFS="`pwgen -B -c -N1 -n 32`"
sed -i -r "s/INSERT_HERE_GENERATED_BLOWFISH_SECRET/$BFS/g" /home/sites/$HNFULL/pub/httpdocs/admin/phpmyadmin/config.inc.php

chown -R nginx:nginx /home/restricted/logs
chown -R nginx:nginx /home/restricted/temp

echo "### Finishing installation"
echo "alias logtail=\"cd /var/log ; tail -f cron dmesg maillog messages secure nginx/error.log mysql/mariadb.log pureftpd.log /home/sites/*/pub/log/*.log\"" >> /root/.bashrc_local

markAsDone
cd $OLDDIR

# eof
