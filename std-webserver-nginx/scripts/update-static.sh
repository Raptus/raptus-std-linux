#!/bin/bash

# Static directory index
SDIBASE="/home/ADMIN-SITE/pub/httpdocs/admin"
SDI="$SDIBASE/sitelist.inc"
CURDIR="`pwd`"

if test -d "$SDIBASE"
then
    echo "<table>" > $SDI
    echo "<tr>" >> $SDI
    echo "<th>Site</th>" >> $SDI
    echo "<th>State</th>" >> $SDI
    echo "<th>PHP</th>" >> $SDI
    echo "<th>Ports</th>" >> $SDI
    echo "</tr>" >> $SDI

    cd /home/sites
    for i in *
    do
        echo "<tr>" >> $SDI
        echo "<td>$i</td>" >> $SDI

        if test -L /etc/nginx/sites-enabled/$i.conf
        then
            echo "<td>Site Enabled</td>" >> $SDI
        else
            echo "<td>Site Disabled</td>" >> $SDI
        fi

        if test "`systemctl is-active php-fpm_$i`" = "active"
        then
            echo "<td>PHP Enabled</td>" >> $SDI
        else
            echo "<td>PHP Disabled</td>" >> $SDI
        fi

        echo "<td>`cat /home/sites/$i/conf/ports.txt`</td>" >> $SDI
        echo "</tr>" >> $SDI
    done
    echo "</table>" >> $SDI
    cd $CURDIR
fi

# eof
