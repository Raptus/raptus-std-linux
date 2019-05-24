#!/bin/bash

source /root/scripts/rsl/common.inc
TEMPLPATH="$PRX_PATH/templates"
ADMINTMPL="default-admin-site"

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
            mkdir -p /home/sites/$site/pub/{error-page,install,httpdocs,log,scripts,sessions,tmp}

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
            sed "s/SITE_NAME/$site/g" $NGINX_TEMPL > $CONFDIR/nginx.conf.IN.1 > $CONFDIR/nginx.conf
            rm -f $CONFDIR/nginx.conf.IN.*
        fi

        if ! test -f $CONFDIR/nginx-rewrites.conf
        then
            cp $TEMPLPATH/nginx-rewrites.conf $CONFDIR/
        fi

        chown $uid:nginx /home/sites/$site
        $PRX_PATH/scripts/reset-access-rights.sh $site >> $LOGFILE

        if test "$template" = "$ADMINTMPL"
        then
            ln -s /home/sites/$site /home/ADMIN-SITE
        else
            echo
            echo "ATTENTION"
            echo "In order to activate the site, use the following command:"
            echo "$PRX_PATH/scripts/manage-site.sh $site site-enable"
            echo
        fi

        $PRX_PATH/scripts/update-static.sh
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
