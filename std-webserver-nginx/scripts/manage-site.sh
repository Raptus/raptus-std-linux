#!/bin/bash

source /root/scripts/rsl/common.inc

function enablePHP()
{
    site=$1
    if test "`systemctl is-active php-fpm_$site.service`" = "active"
    then
        echo "PHP-FPM pool for $site is already enabled" >>/dev/stderr
        exit 1
    else
        systemctl enable /etc/systemd/system/php-fpm_$site.service
        systemctl start php-fpm_$site.service
        systemctl status php-fpm_$site.service
        $WEB_PATH/scripts/update-static.sh
        echo "PHP-FPM pool for $site is now started and enabled"
    fi
}

function disablePHP()
{
    site=$1
    if test "`systemctl is-active php-fpm_$site.service`" = "inactive"
    then
        echo "PHP-FPM pool for $site is already disabled" >>/dev/stderr
        exit 1
    else
        systemctl stop php-fpm_$site.service
        systemctl disable php-fpm_$site.service
        $WEB_PATH/scripts/update-static.sh
        echo "PHP-FPM pool for $site is now stopped and disabled"
    fi
}

function enableSite()
{
    site=$1
    if test -L /etc/nginx/sites-enabled/$site.conf
    then
        echo "Site $site is already enabled." >>/dev/stderr
        exit 1
    else
        ln -s /home/sites/$site/conf/nginx.conf /etc/nginx/sites-enabled/$site.conf
        systemctl reload nginx.service
        $WEB_PATH/scripts/update-static.sh
        echo "Nginx configuration for $site enabled"
    fi
}

function disableSite()
{
    site=$1
    if ! test -L /etc/nginx/sites-enabled/$site.conf
    then
        echo "Site $site is already disabled." >>/dev/stderr
        exit 1
    else
        rm -f /etc/nginx/sites-enabled/$site.conf
        systemctl reload nginx.service
        $WEB_PATH/scripts/update-static.sh
        disablePHP $site
        echo "Nginx configuration for $site enabled"
    fi
}

function deleteSite()
{
    site=$1
    uid="`stat -c %U /home/sites/$site`"

    echo "The site $site will be deleted, if you confirm now"
    if $ASK; then
        echo "Are you sure? [y/n] "
        read YESNO
        test "$YESNO" = "y" || { echo "Deletion aborted!"; exit 1; }
    fi
    echo

    if test -L /etc/nginx/sites-enabled/$site.conf
    then
        disableSite $site
    fi

    # remove FTP account
    ftpusers="`pure-pw list | grep $site | cut -f1`"
    for fu in $ftpusers
    do
        echo "Removing FTP account $fu"
        pure-pw userdel $fu
    done
    pure-pw mkdb

    # del site
    echo -n "Removing site files in /home/sites/$site ... "
    rm -Rf /home/sites/$site
    echo "done"

    # del unix account
    echo -n "Removing unix account $uid ... "
    userdel $uid
    echo "done"

    # del php-fpm pool
    echo -n "Removing php-fpm pool for site $site ... "
    rm -f /etc/systemd/system/php-fpm_$site.service
    echo "done"

    $WEB_PATH/scripts/update-static.sh

    echo
    echo "ATTENTION: Databases are NOT being deleted. Please do this manually!"
    echo
}

function archiveSite()
{
    site=$1
    tstamp="`date +%Y%m%d`"
    archf="/home/archived/$site-$tstamp.tar.gz"
    olddir="`pwd`"
    cd /home/sites

    echo -n "Archiving $sites to tarball $archf ... "
    tar cpfz /home/archived/$site-$tstamp.tar.gz $site
    echo "done"

    echo
    deleteSite $1
}

function setPHPVer()
{
    phpver=$1
    site=$2

    /root/scripts/rsl/std-webserver-nginx/util/install-php.sh $phpver

    ### PHP Compose
        
    cfile="/home/sites/$site/scripts/composer.sh"

    if test -f $cfile; then
        rm $cfile
    fi

    touch $cfile

    echo '#!/bin/bash' >> $cfile
    echo '/opt/'"$phpver"'/bin/php /opt/'"$phpver"'/opt/composer/bin/composer.phar $@' >> $cfile
    echo '# eof' >> $cfile
        
    chmod +x $cfile
        
    ### PHP-CLI

    if ! test -f $CONFDIR/php-cli/php.ini
    then
        rm -rf /home/sites/$site/conf/php-cli/php
        ln -s /opt/php74 /home/sites/$iste/conf/php-cli/php
    fi

    ### PHP-FPM

    if ! test -f $CONFDIR/php-fpm/php.ini
    then
        rm -rf /home/sites/$site/conf/php-fpm/php
        ln -s /opt/php74 /home/sites/$iste/conf/php-fpm/php
    fi

    echo "Switched PHP FPM and CLI for site $site to PHP ${phpver}."
    echo
    echo "In order to activate, the FPM-Pool must be stopped and then started (restart is not enough)"
    echo "systemctl stop php-fpm_$site.service"
    echo "systemctl start php-fpm_$site.service"
    echo
}

function enablePHPNginxPool()
{
    site=$1
    CONFDIR="/home/sites/$site/conf"
    TEMPLPATH="$WEB_PATH/templates"

    if grep "php-fpm-nginx.sock" $CONFDIR/php-fpm/php-fpm.conf &> /dev/null
    then
        echo "Additional PHP-FPM Pool already enabled"
        exit 1
    else
        echo "Adding additional PHP-FPM Pool configuration"
        sed "s/SITE_NAME/$site/g" $TEMPLPATH/php-fpm-nginx-pool.template >> $CONFDIR/php-fpm/php-fpm.conf
    fi

    if test "`systemctl is-active php-fpm_$site.service`" = "inactive"
    then
        echo "PHP-FPM pool for $site is inactive" >>/dev/stderr
        exit 1
    else
        echo "Restarting PHP-FPM Pool"
        systemctl stop php-fpm_$site.service
        systemctl start php-fpm_$site.service
    fi
}

echo
if test $# -ge 2 && (! test -z "$1" || ! test -z "$2")
then
    if ! test -d /home/sites/$1
    then
        echo "Site $1 does not exist." >>/dev/stderr
        echo "Aborting."
        exit 1
    fi

    case $2 in
        site-enable)     enableSite $1
        ;;
        site-disable)    disableSite $1
        ;;
        site-delete)     deleteSite $1
        ;;
        site-archive)    archiveSite $1
        ;;
        php-enable)      enablePHP $1
        ;;
        php-disable)     disablePHP $1
        ;;
        php-set-php74)  setPHPVer php74 $1
        ;;
        php-set-php80)  setPHPVer php80 $1
        ;;
        php-enable-nginx-pool)  enablePHPNginxPool $1
        ;;
        *)
            echo "Unknown action specified." >>/dev/stderr
            echo
            exit 1
        ;;
    esac

else
    echo "Usage: $0 <domain.tld> <action>"
    echo
    echo "Available actions:"
    echo "                       site-enable            enables the site"
    echo "                       site-disable           disables the site, but leaves everything intact"
    echo "                       site-delete            deletes the site (including FTP, but not databases)"
    echo "                       site-archive           archives and then deletes the site"
    echo "                       php-enable             enables the PHP backend"
    echo "                       php-disable            enables the PHP backend"
    echo "                       php-set-php74          switch to PHP v7x for cli and fpm"
    echo "                       php-set-php80          switch to PHP v8x for cli and fpm"
    echo "                       php-enable-nginx-pool  enable separate PHP-FPM Pool running as nginx user rather than host owner"
fi
echo

# eof
