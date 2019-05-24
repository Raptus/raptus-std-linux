#!/bin/bash

source /root/scripts/rsl/common.inc

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

    # del site
    echo -n "Removing site files in /home/sites/$site ... "
    rm -Rf /home/sites/$site
    echo "done"

    # del unix account
    echo -n "Removing unix account $uid ... "
    userdel $uid
    echo "done"

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
    echo "                       site-delete            deletes the site"
    echo "                       site-archive           archives and then deletes the site"
fi
echo

# eof
