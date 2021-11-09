echo "### Setting up php"

dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm >> $LOGFILE 2>&1
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm >> $LOGFILE 2>&1

# If you change this, put latest php version at the end (for phpmyadmin install)
phpvers="php74 php80"

for vers in $phpvers; do
    /root/scripts/rsl/std-webserver-nginx/util/install-php.sh $vers >> $LOGFILE 2>&1
    systemctl disable $vers-php-fpm.service
done

dnf -y install aspell-en >> $LOGFILE 2>&1

mkdir -p /etc/php
cp -R $WEB_PATH/configs-ol/etc-php/conf.d /etc/php/conf.d

mkdir /var/lib/memcache

cp $WEB_PATH/configs-ol/etc-logrotate.d/php-fpm_sites /etc/logrotate.d/php-fpm_sites

#eof
