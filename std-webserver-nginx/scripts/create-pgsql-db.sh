#!/bin/bash

source /root/scripts/rsl/std-linux/common.inc
BASEPATH="/root/scripts/rsl/std-webserver-nginx"

function createDB()
{
    dbname=$1
    dbuser=$2
    dbpass="`apg -n1 -m10 -x10 -a0 -q -M NCL`"

    if ! test "`systemctl is-active postgresql.service`" = "active"
    then
        echo "Enabling PostgreSQL service"
        systemctl enable postgresql.service >> /dev/null 2>&1
        systemctl start postgresql.service
    fi

    if ! test -z "`psql -h localhost -U dbadmin -c 'SELECT DATNAME FROM PG_DATABASE;' template1 | grep $dbname$`"
    then
        echo "PostgreSQL Database $dbname already exists." >>/dev/stderr
        echo "Aborting."
        return
    fi

    echo -n "Creating PostgreSQL database $dbname ... "
    tfile1="`mktemp`"
    tfile2="`mktemp`"
    sed "s/DB_NAME/$dbname/g" $BASEPATH/templates/pgsql-db-creation.template > $tfile1
    sed "s/DB_USER/$dbuser/g" $tfile1 > $tfile2
    sed "s/DB_PASS/$dbpass/g" $tfile2 > $tfile1
    psql -h localhost -U dbadmin -q -f $tfile1 template1
    rm $tfile1
    rm $tfile2
    echo "done"

    passwordInfo "PostgreSQL Database" "$dbuser" "$dbpass" "Database name: $dbname"
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

