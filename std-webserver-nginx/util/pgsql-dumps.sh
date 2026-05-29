#!/bin/bash

# Auto-detect the installed PostgreSQL version so this stays version-agnostic.
PGBIN="`ls -d /usr/pgsql-*/bin 2>/dev/null | sort -V | tail -n1`"
if test -z "$PGBIN"
then
    exit
fi
PGVER="`echo "$PGBIN" | sed -r 's#.*/pgsql-([0-9]+)/bin#\1#'`"

# only do something if service is active
if ! test "`systemctl is-active postgresql-$PGVER.service`" = "active"
then
    exit
fi

DUMPDIR="/home/backups/pgsql"
DATABASES="`$PGBIN/psql -h localhost -U dbadmin -d template1 -t -A -F, -c '\l'`"

test -d "$DUMPDIR" || mkdir -p "$DUMPDIR"
for i in $DATABASES
do
    DB="`echo $i | cut -f1 -d,`"
    if ! test $DB = "template0" && test -z "`echo $DB | grep =`"
    then
        DBE="`echo $DB | sed 's/\//_/'`"
        DUMPFILE="$DUMPDIR/pgsql_"$DBE"_dump_`date +%H`h.pgsql"

        #echo "Dumping $DB to $DUMPFILE"
        $PGBIN/pg_dump -h localhost -U dbadmin --no-owner --no-privileges "$DB" > $DUMPFILE
        gzip -9 --force --rsyncable $DUMPFILE
    fi
done

# eof
