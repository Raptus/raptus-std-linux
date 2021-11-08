echo "### Setting up php"

dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm >> $LOGFILE 2>&1
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm >> $LOGFILE 2>&1

/root/scripts/rsl/std-webserver-nginx/util/install-php.sh php74 >> $LOGFILE 2>&1
/root/scripts/rsl/std-webserver-nginx/util/install-php.sh php80 >> $LOGFILE 2>&1

dnf -y install aspell-en >> $LOGFILE 2>&1

mkdir -p /etc/php
cp -R $WEB_PATH/configs-ol/etc-php/conf.d /etc/php/conf.d

mkdir /var/lib/memcache

cp $WEB_PATH/configs-ol/etc-logrotate.d/php-fpm_sites /etc/logrotate.d/php-fpm_sites

systemctl disable php74-php-fpm.service
systemctl disable php80-php-fpm.service

### Composer

mkdir -p /opt/composer/bin
getFileFromURL https://getcomposer.org/composer.phar /opt/composer/bin
cp $WEB_PATH/configs-ol/composer-wrapper.sh /opt/composer/bin/composer
ln -s /opt/composer/bin/composer /usr/local/bin
