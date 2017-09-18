#!/bin/bash

# only do something if service is active
if ! test "`systemctl is-active postgresql.service`" = "active"
then
    exit 
fi

DUMPDIR="/home/backups/pgsql"
DATABASES="`/usr/bin/psql -h localhost -U dbadmin -d template1 -t -A -F, -c '\l'`"

test -d "$DUMPDIR" || mkdir -p "$DUMPDIR"
for i in $DATABASES
do
    DB="`echo $i | cut -f1 -d,`"
    if ! test $DB = "template0" && test -z "`echo $DB | grep =`"
    then
        DBE="`echo $DB | sed 's/\//_/'`"
        DUMPFILE="$DUMPDIR/pgsql_"$DBE"_dump_`date +%H`h.pgsql"

        #echo "Dumping $DB to $DUMPFILE"
        /usr/bin/pg_dump -h localhost -U dbadmin --no-owner --no-privileges "$DB" > $DUMPFILE
        gzip -9 --force --rsyncable $DUMPFILE
    fi
done

# eof
