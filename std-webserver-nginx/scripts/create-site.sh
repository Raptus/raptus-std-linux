#!/bin/bash

source /root/scripts/rsl/common.inc
TEMPLPATH="$WEB_PATH/templates"
ADMINTMPL="default-admin-site"

DEFPHPMAJ="7"
DEFPHPBINS="php56 php72"
PORTBASE="10010"
PORTSIZE="9"
PORTFILE="/var/rsl/state/last-port-offset"
PORT=""
SSL_CERT_HOSTNAME="`hostname`"

function updateConfig()
{
        site=$1
        template=$2
        uid="s_$site"

        if ((${#uid} > 32 ))
        then
            echo "Site name too long to map to uid/gid."
            uuid="`uuid -v1 | cut -f1 -d-`"
            uid="s_`echo ${site:0:15}`_$uuid"
            echo "Adopted uid/gid will be: $uid"
        fi

        if test -z "`getent passwd $uid`"
        then
            echo "Creating unix account $uid"
            useradd -d /home/sites/$site -g nginx --shell /bin/false --no-create-home --no-log-init $uid
        fi

        if ! test -d /home/sites/$site
        then
            mkdir -p /home/sites/$site/{auth,cache,conf,pub,run,scripts,ssl}
            mkdir -p /home/sites/$site/conf/{php-cli,php-fpm}
            mkdir -p /home/sites/$site/pub/{error-page,install,httpdocs,log,scripts,sessions,tmp}
            mkdir -p /home/sites/$site/pub/tmp/fcgi

            ln -s /home/sites/$site/pub/httpdocs /home/sites/$site/
            ln -s /etc/ssl/selfsigned_$SSL_CERT_HOSTNAME/$SSL_CERT_HOSTNAME.pem /home/sites/$site/ssl/package.pem
            ln -s /etc/ssl/selfsigned_$SSL_CERT_HOSTNAME/$SSL_CERT_HOSTNAME.key /home/sites/$site/ssl/private.key
        fi

        CONFDIR="/home/sites/$site/conf"
        if ! test -f $CONFDIR/ports.txt
        then
            if ! test -f $PORTFILE
            then
                PORT=$PORTBASE
            else
                PORT="`cat $PORTFILE`"
                PORT=$((PORT+PORTSIZE+1))
            fi
            if ! test -z "$PORT"
            then
                TXT="Reserved $PORTSIZE ports ($PORT:$((PORT+PORTSIZE)))"
                echo $TXT > $CONFDIR/ports.txt
                echo $PORT > $PORTFILE
                echo $TXT
            else
                echo "Failed to obtain a port for this site!" >>/dev/stderr
                exit 1
            fi
        fi

        if ! test -f $CONFDIR/nginx.conf
        then
            sed "s/SITE_NAME/$site/g" $NGINX_TEMPL > $CONFDIR/nginx.conf.IN.1
            sed "s/PHPFPM_PORT/$PORT/g" $CONFDIR/nginx.conf.IN.1 > $CONFDIR/nginx.conf
            rm -f $CONFDIR/nginx.conf.IN.*
        fi

        if ! test -f $CONFDIR/nginx-rewrites.conf
        then
            cp $TEMPLPATH/nginx-rewrites.conf $CONFDIR/
        fi

        for PHPBINS in $DEFPHPBINS
        do
            ln -s /opt/$PHPBINS $CONFDIR/php-cli/$PHPBINS
            ln -s /opt/$PHPBINS $CONFDIR/php-fpm/$PHPBINS
        done

        ### PHP-CLI

        if ! test -f $CONFDIR/php-cli/php-major
        then
            echo "Setting PHP CLI major version to $DEFPHPMAJ"
            echo "$DEFPHPMAJ" > $CONFDIR/php-cli/php-major
        fi

        if ! test -f $CONFDIR/php-cli/php5.ini
        then
            sed "s/SITE_NAME/$site/g" $TEMPLPATH/php5-cli.ini.template > $CONFDIR/php-cli/php5.ini
            ln -s /etc/php5/conf.d /home/sites/$site/conf/php-cli/php5-conf.d
        fi

        if ! test -f $CONFDIR/php-cli/php7.ini
        then
            sed "s/SITE_NAME/$site/g" $TEMPLPATH/php7-cli.ini.template > $CONFDIR/php-cli/php7.ini
            ln -s /etc/php7/conf.d /home/sites/$site/conf/php-cli/php7-conf.d
        fi

        if ! test -f /home/sites/$site/scripts/php-cli.sh
        then
            sed "s/SITE_NAME/$site/g" $TEMPLPATH/php-cli.sh.template > /home/sites/$site/scripts/php-cli.sh
        fi

        ### PHP-FPM

        if ! test -f $CONFDIR/php-fpm/php-major
        then
            echo "Setting PHP-FPM pool major version to $DEFPHPMAJ"
            echo "$DEFPHPMAJ" > $CONFDIR/php-fpm/php-major
        fi

        if ! test -f $CONFDIR/php-fpm/php5.ini
        then
            sed "s/SITE_NAME/$site/g" $TEMPLPATH/php5-fpm.ini.template > $CONFDIR/php-fpm/php5.ini
            ln -s /etc/php5/conf.d /home/sites/$site/conf/php-fpm/php5-conf.d
        fi

        if ! test -f $CONFDIR/php-fpm/php7.ini
        then
            sed "s/SITE_NAME/$site/g" $TEMPLPATH/php7-fpm.ini.template > $CONFDIR/php-fpm/php7.ini
            ln -s /etc/php7/conf.d /home/sites/$site/conf/php-fpm/php7-conf.d
        fi

        if ! test -f /home/sites/$site/scripts/php-fpm.sh
        then
            sed "s/SITE_NAME/$site/g" $TEMPLPATH/php-fpm.sh.template > /home/sites/$site/scripts/php-fpm.sh
        fi

        if ! test -f /etc/systemd/system/php-fpm_$site.service
        then
            sed "s/SITE_NAME/$site/g" $TEMPLPATH/php-fpm-systemd-unit.template > /etc/systemd/system/php-fpm_$site.service
            systemctl daemon-reload
        fi

        if ! test -f $CONFDIR/php-fpm/php-fpm.conf
        then
            echo "Creating PHP-FPM pool configuration"
            sed "s/SITE_NAME/$site/g" $TEMPLPATH/php-fpm-pool.template > $CONFDIR/php-fpm/php-fpm.conf.IN.1
            sed "s/UID_NAME/$uid/g" $CONFDIR/php-fpm/php-fpm.conf.IN.1 > $CONFDIR/php-fpm/php-fpm.conf.IN.2
            sed "s/PHPFPM_PORT/$PORT/g" $CONFDIR/php-fpm/php-fpm.conf.IN.2 > $CONFDIR/php-fpm/php-fpm.conf
            rm -f $CONFDIR/php-fpm/php-fpm.conf.IN.*
        fi

        chown $uid:nginx /home/sites/$site
        $WEB_PATH/scripts/reset-access-rights.sh $site >> $LOGFILE

        if test "$template" = "$ADMINTMPL"
        then
            ln -s /home/sites/$site /home/ADMIN-SITE
        else
            echo
            echo "ATTENTION"
            echo "In order to activate the site, use the following command:"
            echo "$WEB_PATH/scripts/manage-site.sh $site site-enable"
            echo
            echo "If you need PHP in this site, you need to enable it manually:"
            echo "$WEB_PATH/scripts/manage-site.sh $site php-enable"
            echo
        fi

        $WEB_PATH/scripts/update-static.sh
}

echo
if test $# -ge 2 && (! test -z "$1" || ! test -z "$2")
then
        NGINX_TEMPL="$TEMPLPATH/nginx-site-$2.template"
        if ! test -f "$NGINX_TEMPL"
        then
            echo "Cannot find template $2" >>/dev/stderr
            exit 1
        fi

        if test "$2" = "$ADMINTMPL" && test -L "/home/ADMIN-SITE"
        then
            echo "There can only be one default admin site per host!" >>/dev/stderr
            echo "Do you know what you are doing?" >>/dev/stderr
            exit 1
        fi

        updateConfig $1 $2
else
    echo "Usage: $0 <domain.tld> <template>"
    echo
    echo "Available templates:"
    ls -1 $TEMPLPATH/nginx-site-*.template | perl -pe "s/.*nginx-site-(.*).template/\1/"
    echo
fi
echo

# eof
