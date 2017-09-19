#!/bin/bash

if test -z "`yum list installed | grep atomic-release.noarch`"
then
    echo "Atomic repo not found"
    exit 1
fi

source /root/scripts/rsl/common.inc
checkLockFile
touch $LOGFILE

echo "### Migrating Atomic repo packages to Remi"
echo "    All Atomic packages and files will be erased!"
echo "    Logfile: $LOGFILE"
askConfirmation

OLDDIR="`pwd`"
cd $WEB_PATH

echo "### Stopping all php-fpm processes (manual restart or reboot required)"
systemctl stop php-fpm_*

echo "### Removing Atomic repositories"
yum -y erase atomic-release.noarch quantum-release.noarch >> $LOGFILE 2>&1
yum -y clean all >> $LOGFILE 2>&1

echo "### Uninstalling ALL packages from Atomic repositories"
rpm -e --nodeps `yum list installed | grep atomic | cut -f1 -d' '` >> $LOGFILE 2>&1
rm -Rf /opt/atomic /opt/rh >> $LOGFILE
rm /opt/php5 /opt/php7 >> $LOGFILE

echo "### Fixing dependencies from Atomic"
yum -y install GeoIP.x86_64 GeoIP-update.noarch memcached.x86_64 libmemcached.x86_64 \
               jemalloc.x86_64 mysqltuner.noarch >> $LOGFILE 2>&1

echo "### Installing Remi repository"
yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm >> $LOGFILE 2>&1

echo "### Installing PHP v5.6 and v7.1 from Repi"
PHPVERS="php56 php71"
for PHPVER in $PHPVERS
do
    yum -y install \
        $PHPVER-php-fpm \
        $PHPVER-php-cli \
        $PHPVER-php-bcmath \
        $PHPVER-php-dba \
        $PHPVER-php-embedded \
        $PHPVER-php-gd \
        $PHPVER-php-gmp \
        $PHPVER-php-intl \
        $PHPVER-php-json \
        $PHPVER-php-mbstring \
        $PHPVER-php-mcrypt \
        $PHPVER-php-mysqlnd \
        $PHPVER-php-opcache \
        $PHPVER-php-pdo \
        $PHPVER-php-pgsql \
        $PHPVER-php-process \
        $PHPVER-php-pspell \
        $PHPVER-php-recode \
        $PHPVER-php-snmp \
        $PHPVER-php-soap \
        $PHPVER-php-tidy \
        $PHPVER-php-xml \
        $PHPVER-php-xmlrpc \
        $PHPVER-php-zip >> $LOGFILE 2>&1
done
yum -y install aspell-de aspell-es aspell-fr aspell-it >> $LOGFILE 2>&1

echo "### Enabling PHP v5.6 and v7.1"
ln -s /opt/remi/php56/root /opt/php5
ln -s /opt/remi/php71/root /opt/php7

markAsDone
cd $OLDDIR

# eof