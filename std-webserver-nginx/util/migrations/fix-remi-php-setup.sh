#!/bin/bash

source /root/scripts/rsl/common.inc
checkLockFile
touch $LOGFILE

echo "### Fixing PHP Remi Installation from before August 2019"
echo "    Fix will be applied for php71 to php73"
echo "    For additional PHP versions, edit PHPVERS"
echo "    Logfile: $LOGFILE"
askConfirmation

echo "### Installing additional PHP packages"
PHPVERS="php71 php72 php73"
for PHPVER in $PHPVERS
do
    /root/scripts/rsl/std-webserver-nginx/util/install-php.sh $PHPVER >> $LOGFILE 2>&1
done

echo "### Downloading and placing PHP module configurations"
TEMP_PATH=$(mktemp -d)
cd $TEMP_PATH
wget https://bitbucket.org/raptus-it-services/raptus-std-linux/get/0fae43752820.zip >> $LOGFILE 2>&1
unzip -j ./0fae43752820.zip "raptus-it-services-raptus-std-linux-0fae43752820/std-webserver-nginx/configs-centos/etc-php7/conf.d/*" -d /etc/php7/conf.d/ >> $LOGFILE 2>&1
cd $WEB_PATH
rm -rf $TEMP_PATH

echo "### Updating system"
yum update

echo "### Fixing wrapper scripts and restart PHP"
find /home/sites -name php-cli.sh -exec sed -i -r "s/^(PHP_INI_SCAN_DIR.*)/\export \1/g" {} \;
find /home/sites -name php-fpm.sh -exec sed -i -r "s/^(PHP_INI_SCAN_DIR.*)/\export \1/g" {} \;

cd /etc/systemd/system && for i in php-fpm_* ; do systemctl start $i ; done
# eof
