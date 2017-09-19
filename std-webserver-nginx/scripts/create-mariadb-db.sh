#!/bin/bash

source /root/scripts/rsl/common.inc
BASEPATH="/root/scripts/rsl/std-webserver-nginx"

function createDB()
{
    dbname=$1
    dbuser=$2
    dbpass="`apg -n1 -m10 -x10 -a0 -q -M NCL`"

    if ((${#dbuser} > 16 ))
    then
        echo "Username  is too long, max. 16 characters allowed." >>/dev/stderr
        echo "Aborting."
        return
    fi

    if ! test -z "`mysql --user=dbadmin --batch --execute 'SHOW DATABASES;' | grep $dbname`"
    then
        echo "MariaDB Database $dbname already exists." >>/dev/stderr
        echo "Aborting."
        return
    fi

    echo -n "Creating MariaDB database $dbname ... "
    tfile1="`mktemp`"
    tfile2="`mktemp`"
    sed "s/DB_NAME/$dbname/g" $BASEPATH/templates/mariadb-db-creation.template > $tfile1
    sed "s/DB_USER/$dbuser/g" $tfile1 > $tfile2
    sed "s/DB_PASS/$dbpass/g" $tfile2 > $tfile1
    mysql -h localhost -u dbadmin < $tfile1
    rm $tfile1
    rm $tfile2
    echo "done"

    passwordInfo "MariaDB Database" "$dbuser" "$dbpass" "Database name: $dbname"
    echo "Created user $dbuser with password:  $dbpass"
}

echo
if test $# -ge 2 &&
   ! test -z "$1" &&
   ! test -z "$2"
then
    createDB $1 $2
else
    echo "Usage: $0 <db_name> <db_user>"
fi
echo

