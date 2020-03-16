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
cd $PRX_PATH

echo "###"
echo "###"
echo "###"
echo "###"
echo "###"
echo "###"
echo "###"
echo

echo "### Standard setup for upstream proxy"
echo "    Logfile: $LOGFILE"
askConfirmation

echo "### Setting up basic structure"
mkdir -p /home/archived
mkdir -p /home/sites
mkdir -p /home/restricted/{scripts,logs,temp}

# ATTENTION: Dependencies!!!
source $PRX_PATH/parts-centos/standard-webserver.inc
source $PRX_PATH/parts-centos/standard-memcached.inc
source $PRX_PATH/parts-centos/standard-nginx.inc
source $PRX_PATH/parts-centos/standard-certbot.inc

echo "### Setting up default/admin site $HNFULL"
$PRX_PATH/scripts/create-site.sh $HNFULL default-admin-site >> $LOGFILE 2>&1
admin_site_uid="`stat -c %U /home/sites/$site`"
cp -Rp $PRX_PATH/admin-site/* /home/ADMIN-SITE/pub/httpdocs/
DVP="`apg $APGOPTS`"
htpasswd /home/sites/$HNFULL/auth/htpasswd admin $DVP
passwordInfo "Default site" "admin" "$DVP" "https://$HNFULL/admin"
$PRX_PATH/scripts/manage-site.sh $HNFULL site-enable >> $LOGFILE 2>&1

chown -R nginx:nginx /home/restricted/logs
chown -R nginx:nginx /home/restricted/temp

echo "### Finishing installation"
echo "alias logtail=\"cd /var/log ; tail -f cron dmesg maillog messages secure nginx/error.log /home/sites/*/pub/log/*.log\"" >> /root/.bashrc_local

markAsDone
cd $OLDDIR

# eof
