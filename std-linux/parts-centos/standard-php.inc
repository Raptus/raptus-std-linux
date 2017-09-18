echo "### Setting up php"

yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm >> $LOGFILE 2>&1

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

cp -R $SCRIPTPATH/std-linux/configs-centos/etc-php5/conf.d /etc/php5/conf.d
cp -R $SCRIPTPATH/std-linux/configs-centos/etc-php7/conf.d /etc/php7/conf.d

mkdir /var/lib/memcache
mkdir /var/php5-fpm
useradd -d /var/php5-fpm -M -U -s /sbin/nologin php5-fpm

ln -s /opt/remi/php56/root /opt/php5
ln -s /opt/remi/php71/root /opt/php7

cp $SCRIPTPATH/std-linux/configs-centos/etc-logrotate.d/php-fpm_sites /etc/logrotate.d/php-fpm_sites