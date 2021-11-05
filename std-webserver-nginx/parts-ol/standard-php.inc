echo "### Setting up php"

dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm >> $LOGFILE 2>&1

/root/scripts/rsl/std-webserver-nginx/util/install-php.sh php71 >> $LOGFILE 2>&1
/root/scripts/rsl/std-webserver-nginx/util/install-php.sh php72 >> $LOGFILE 2>&1
/root/scripts/rsl/std-webserver-nginx/util/install-php.sh php73 >> $LOGFILE 2>&1

dnf -y install aspell-en >> $LOGFILE 2>&1

mkdir -p /etc/php7
cp -R $WEB_PATH/configs-ol/etc-php7/conf.d /etc/php7/conf.d

mkdir /var/lib/memcache

cp $WEB_PATH/configs-ol/etc-logrotate.d/php-fpm_sites /etc/logrotate.d/php-fpm_sites

systemctl disable php71-php-fpm.service
systemctl disable php72-php-fpm.service
systemctl disable php73-php-fpm.service

### Composer

mkdir -p /opt/composer/bin
getFileFromURL https://getcomposer.org/composer.phar /opt/composer/bin
cp $WEB_PATH/configs-ol/composer-wrapper.sh /opt/composer/bin/composer
ln -s /opt/composer/bin/composer /usr/local/bin
