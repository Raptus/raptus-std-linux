#!/bin/bash

if test -z "$1"
then
    echo "Usage: $0 <php-version-no-dots>"
    echo
    echo "NOTE:     Specify PHP version without dots"
    echo "EXAMPLE:  $0 php80"
    echo
    exit 1
fi

PHPVER="$1"
if test "`dnf -q search $PHPVER-php-fpm 2>&1 | grep 'No matches found for'`"
then
    echo "Cannot find PHP package $PHPVER-php-fpm. Aborting ..."
    exit 1
fi

dnf -y install \
    $PHPVER-php-fpm \
    $PHPVER-php-cli \
    $PHPVER-php-bcmath \
    $PHPVER-php-dba \
    $PHPVER-php-embedded \
    $PHPVER-php-gd \
    $PHPVER-php-gmp \
    $PHPVER-php-intl \
    $PHPVER-php-json \
    $PHPVER-php-pecl-json-post \
    $PHPVER-php-pecl-imagick \
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
    $PHPVER-php-zip >> /dev/null

ln -sfT /opt/remi/$PHPVER/root /opt/$PHPVER

# eof
