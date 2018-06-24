echo "### Setting up php"

yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm >> $LOGFILE 2>&1

/root/scripts/rsl/std-webserver-nginx/util/install-php.sh php56 >> $LOGFILE 2>&1
/root/scripts/rsl/std-webserver-nginx/util/install-php.sh php70 >> $LOGFILE 2>&1
/root/scripts/rsl/std-webserver-nginx/util/install-php.sh php71 >> $LOGFILE 2>&1
/root/scripts/rsl/std-webserver-nginx/util/install-php.sh php72 >> $LOGFILE 2>&1
/root/scripts/rsl/std-webserver-nginx/util/install-php.sh php73 >> $LOGFILE 2>&1

yum -y install aspell-de aspell-es aspell-fr aspell-it >> $LOGFILE 2>&1

mkdir -p /etc/php5
mkdir -p /etc/php7
cp -R $WEB_PATH/configs-centos/etc-php5/conf.d /etc/php5/conf.d
cp -R $WEB_PATH/configs-centos/etc-php7/conf.d /etc/php7/conf.d

mkdir /var/lib/memcache
mkdir /var/php5-fpm
useradd -d /var/php5-fpm -M -U -s /sbin/nologin php5-fpm

cp $WEB_PATH/configs-centos/etc-logrotate.d/php-fpm_sites /etc/logrotate.d/php-fpm_sites

### Composer

mkdir -p /opt/composer/bin
getFileFromURL https://getcomposer.org/composer.phar /opt/composer/bin
cp $WEB_PATH/configs-centos/composer-wrapper.sh /opt/composer/bin/composer
ln -s /opt/composer/bin/composer /usr/local/bin

