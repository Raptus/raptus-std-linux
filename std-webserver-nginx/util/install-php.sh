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

echo "Installing $PHPVER"

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
    $PHPVER-php-iconv \
    $PHPVER-php-snmp \
    $PHPVER-php-soap \
    $PHPVER-php-tidy \
    $PHPVER-php-xml \
    $PHPVER-php-xmlrpc \
    $PHPVER-php-zip >> /dev/null

if [[ $PHPVER = *"php7"* ]]; then
    dnf -y install $PHPVER-php-recode >> /dev/null
fi

ln -sfT /opt/remi/$PHPVER/root /opt/$PHPVER

# Install composer

mkdir -p /opt/$PHPVER/opt/composer/bin
cd /opt/$PHPVER/opt/composer/bin

EXPECTED_CHECKSUM="$($PHPVER -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
$PHPVER -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$($PHPVER -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
then
    >&2 echo "ERROR: Installation of PHP-$PHPVER failed: Invalid installer checksum"
    rm composer-setup.php
    exit 1
fi

$PHPVER composer-setup.php --quiet
rm composer-setup.php

# eof
