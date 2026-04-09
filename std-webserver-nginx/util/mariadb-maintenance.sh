#!/bin/bash

# only do something if service is active
if ! test "`systemctl is-active mariadb.service`" = "active"
then
    exit
fi

# run optimize only on first sunday of month
if [ "$(date +%u)" = "7" ] && [ "$(date +%d)" -le 7 ]
then
    /usr/bin/mariadb-check --all-databases --optimize -u dbadmin > /var/log/mariadb-maintenance.log
else
    /usr/bin/mariadb-check --all-databases --check-only-changed -u dbadmin > /var/log/mariadb-maintenance.log
fi

# eof
