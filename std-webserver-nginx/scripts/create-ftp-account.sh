#!/bin/bash

source /root/scripts/rsl/std-linux/common.inc

function createFTP()
{
    site=$1
    ftpuser=$2
    ftppass="`apg -n1 -m10 -x10 -a0 -q -M NCL`"

    if ! test -d /home/sites/$site
    then
        echo "Site $site does not exist."
        echo "Aborting."
        return
    fi

    if ! test -z "`pure-pw list | grep $ftpuser`"
    then
        echo "FTP account $ftpuser already exists."
        echo "Aborting."
        return
    fi

    if ! test -z "`pure-pw list | grep $site`"
    then
        echo "FTP account for site $site already exists."
        echo "Aborting."
        return
    fi

    if ! test "`systemctl is-active pure-ftpd.service`" = "active"
    then
        echo "Enabling FTP service"
        systemctl enable pure-ftpd.service >> /dev/null 2>&1
        systemctl start pure-ftpd.service
    fi

    uid="`stat -c %U /home/sites/$site`"

    echo -n "Creating FTP User $ftpuser for site $site ... "
    tfile="`mktemp`"
    echo "$ftppass" > $tfile
    echo "$ftppass" >> $tfile
    pure-pw useradd $ftpuser -u $uid -g nginx -d /home/sites/$site/pub < $tfile >/dev/null
    pure-pw mkdb
    rm $tfile    
    echo "done"

    passwordInfo "FTP Account" "$ftpuser" "$ftppass" "ftp://$site"
    echo "Created FTP User $ftpuser with password: $ftppass"

}

echo
if test $# -ge 2 &&
   ! test -z "$1" &&
   ! test -z "$2"
then
    createFTP $1 $2
else
    echo "Usage: $0 <site> <ftp_user>"
fi
echo

