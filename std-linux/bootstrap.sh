#!/bin/bash

source /root/scripts/rsl/std-linux/common.inc
checkHostname
checkInstall

echo "###"
echo "###"
echo "###"
echo "###"
echo "###"
echo "###"
echo "###"
echo 

if ! test -f "$CFGFILE"
then
    echo "### Cannot find the configuration file: $CFGFILE"
    echo ""
    echo "    Example configuration:"
    echo ""
    echo "        OUR_IPS=1.2.3.4,1.2.3.5            # only IP's allowed"
    echo "        ADMIN_EMAIL=yourname@domain.tld    # only 1 email allowed"
    echo ""
    exit 1
fi

if test -f "$CFGFILE"
then
    source "$CFGFILE"
    if test -z "$OUR_IPS" && test -z "$ADMIN_EMAIL"
    then
        echo "Configuration file values may not be empty"
        exit 1
    fi

    echo "### Using configuration from $CFGFILE"
    OUR_IPS_SPACED="`echo $OUR_IPS | tr ',' ' '`"
fi

checkLockFile
touch $LOGFILE
OLDDIR="`pwd`"
cd $SCRIPTPATH

echo "### Bootstrapping this system with Linux standards"
echo "    Logfile: $LOGFILE"
askConfirmation

source /root/scripts/rsl/std-linux/bootstrap-$DISTRO.sh

markAsDone
cd $OLDDIR

#eof