echo "### Setting up php base"

dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm >> $LOGFILE 2>&1
dnf -y install dnf-utils http://rpms.remirepo.net/enterprise/remi-release-9.rpm >> $LOGFILE 2>&1

phpvers="php83"

/root/scripts/rsl/std-webserver-nginx/util/install-php.sh $phpvers >> $LOGFILE 2>&1

dnf -y install aspell-en >> $LOGFILE 2>&1

mkdir -p /etc/php
cp -R $WEB_PATH/configs/etc-php/conf.d /etc/php/conf.d

mkdir /var/lib/memcache

cp $WEB_PATH/configs/etc-logrotate.d/php-fpm_sites /etc/logrotate.d/php-fpm_sites

systemctl disable $phpvers-php-fpm.service

#eof
