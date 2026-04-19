#!/bin/bash

source /root/scripts/rsl/common.inc

function createBasicAuth()
{
    site=$1
    httpuser=$2
    httppass="`pwgen -B -c -N1 -n 15`"
    authfile="/home/sites/$site/auth/htpasswd"

    if ! test -d /home/sites/$site
    then
        echo "Site $site does not exist." >>/dev/stderr
        echo "Aborting."
        return
    fi

    if test -f "$authfile"
    then
        if ! test -z "`cat $authfile | grep $httpuser`"
        then
            echo "User $httpuser already exists." >>/dev/stderr
            echo "Aborting."
            return
        fi
    fi

    echo -n "Creating user $httpuser for site $site ... "
    htpasswd $authfile $httpuser $httppass
    echo "done"

    passwordInfo "HTTP BasicAuth" "$httpuser" "$httppass" "http://$site"
    echo "Created HTTP BasicAuth user $httpuser with password:  $httppass"
}

echo
if test $# -ge 2 &&
   ! test -z "$1" &&
   ! test -z "$2"
then
    createBasicAuth $1 $2
else
    echo "Usage: $0 <site> <http_user>"
fi
echo
