#!/bin/bash

function setChmod()
{
    if ! test -d $1
    then
        return
    fi

    find $1 -type f -exec chmod $2 {} \;
    find $1 -type d -exec chmod $3 {} \;
}

function resetSiteRights()
{
    site=$1

    if ! test -d "/home/sites/$site"
    then
        echo "Site $site not found!"
        exit 1
    fi

    echo -n "Resetting access rights for $site ... "
    uid="`stat -c %U /home/sites/$site`"

    # Policy: owner is php and has write access, webserver is read only
    chown -R $uid:nginx /home/sites/$site
    setChmod /home/sites/$site "u=+rw,g=+r,o=" "u=+rwx,g=+rx,o="

    # Give write access to php and webserver (only needed parts)
    setChmod /home/sites/$site/cache "ug=+rw,o=+r" "ug=+rwx,o=+rx"
    setChmod /home/sites/$site/run "ug=+rw,o=+r" "ug=+rwx,o=+rx"
    setChmod /home/sites/$site/pub/tmp "ug=+rw,o=+r" "ug=+rwx,o=+rx"
    setChmod /home/sites/$site/pub/log "ug=+rw,o=+r" "ug=+rwx,o=+rx"

    # Only root may edit these files, webserver and php are read only
    chown -R root:root /home/sites/$site/{auth,conf,ssl}
    setChmod /home/sites/$site/auth "u=+rw,go=+r" "u=+rwx,go=+rx"
    setChmod /home/sites/$site/conf "u=+rw,go=+r" "u=+rwx,go=+rx"
    setChmod /home/sites/$site/ssl "u=+rw,go=+r" "u=+rwx,go=+rx"

    # Restrict and allow to execute custom scripts
    chown -R root:root /home/sites/$site/scripts
    setChmod /home/sites/$site/scripts "u=+rwx,go=+rx" "u=+rwx,go=+rx"

    # Restrict and allow to execute custom scripts site specific
    chown -R $uid:nginx /home/sites/$site/pub/scripts
    setChmod /home/sites/$site/pub/scripts "u=+rwx,go=+r" "u=+rwx,go=+rx"

    echo "done"
}

echo
if test $# -ge 1 &&
   ! test -z "$1"
then
    resetSiteRights $1
else
    echo "Rights of all sites will be reset"
    echo "Are you sure? [y/n] "
    read YESNO
    echo  
    echo  
    if ! test "$YESNO" = "y"
    then
        echo "Aborted!"
        exit 1
    fi

    OLDDIR="`pwd`"
    cd /home/sites
    for site in *
    do
        resetSiteRights $site
    done
    cd $OLDDIR
fi
echo

# eof
