#!/bin/bash

# only do something if service is active
if ! test "`systemctl is-active mysql.service`" = "active"
then
    exit
fi

DUMPDIR="/home/backups/mariadb"
DATABASES="`mysql --user=dbadmin --batch --execute 'show databases;'`"

test -d "$DUMPDIR" || mkdir -p "$DUMPDIR"
for i in $DATABASES
do
  if ! test $i = "Database" && ! test $i = "performance_schema"
  then
    DUMPFILE="$DUMPDIR/mysql_"$i"_dump_`date +%H`h.mysql"

    #echo "Dumping $i to $DUMPFILE"
    mysqldump --user=dbadmin --single-transaction --allow-keywords --events $i > $DUMPFILE
    gzip -9 --force --rsyncable $DUMPFILE
  fi
done

# eof
