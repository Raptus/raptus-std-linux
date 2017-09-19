#!/bin/bash

source /root/scripts/std-linux/common.inc
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
	echo "    If you want to create one, do so now, before continuing."
	echo ""
	echo "    Example configuration:"
	echo ""
	echo "        OUR_IPS=1.2.3.4,1.2.3.5,host1.domain.tld"
	echo "        ADMIN_EMAIL=yourname@domain.tld"
	echo ""
	askConfirmation
else
	echo "### Using custom configuration file $CFGFILE"
fi

if ! test -f "$CFGFILE"
then
	source "$CFGFILE"
	# TODOOOOOOOOOOOOOO;: PARSE OURIPS
fi

checkLockFile
touch $LOGFILE
OLDDIR="`pwd`"
cd $SCRIPTPATH

echo "### Bootstrapping this system with Linux standards"
echo "    Logfile: $LOGFILE"
askConfirmation

source /root/scripts/std-linux/bootstrap-$DISTRO.sh

markAsDone
cd $OLDDIR

#eof