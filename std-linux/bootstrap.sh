#!/bin/bash

if ! test -f "$CFGFILE"
then
    echo "### Cannot find the configuration file: $CFGFILE"
    echo ""
    echo "    Example configuration:"
    echo ""
    echo "        OUR_IPS=1.2.3.4,1.2.3.5            # Allowed by Firewall etc."
    echo "        ADMIN_EMAIL=yourname@domain.tld    # Mail notifications"
    echo "        ACME_ACCOUNT=yourname@domain.tld   # Let's Encrypt account"
    echo "        ENABLE_FIREWALL=yes                # allowed: yes/no"
    echo ""
    exit 1
fi

source /root/scripts/rsl/common.inc
checkHostname
checkInstall
checkLockFile
touch $LOGFILE
OLDDIR="`pwd`"
cd $SCRIPTPATH

echo "###"
echo "###"
echo "###"
echo "###"
echo "###"
echo "###"
echo "###"
echo 
echo "### Bootstrapping this system with Linux standards"
echo "    Logfile: $LOGFILE"
askConfirmation

source $SCRIPTPATH/bootstrap-$DISTRO.sh

markAsDone
cd $OLDDIR

#eof