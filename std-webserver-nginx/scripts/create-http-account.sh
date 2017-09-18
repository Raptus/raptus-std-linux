#!/bin/bash

source /root/scripts/std-linux/common.inc

function createBasicAuth()
{
    site=$1
    httpuser=$2
    httppass="`apg -n1 -m10 -x10 -a0 -q -M NCL`"
    authfile="/home/sites/$site/auth/htpasswd"

    if ! test -d /home/sites/$site
    then
        echo "Sites $site does not exist."
        echo "Aborting."
        return
    fi

    new=""
    if ! test -f "$authfile"
    then
        new="-c"
    else
        if ! test -z "`cat $authfile | grep $httpuser`"
        then
            echo "User $httpuser already exists."
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

