#!/bin/bash

# only do something if service is active
if ! test "`systemctl is-active mariadb.service`" = "active"
then
    exit
fi

/usr/bin/mysqlcheck --all-databases --check-only-changed -u dbadmin > /var/log/mariadb-maintenance.log

# eof
