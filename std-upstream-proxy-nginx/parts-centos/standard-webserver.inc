echo "### Installing base packages"

dnf -y install mailx >> $LOGFILE 2>&1
dnf -y --enablerepo=PowerTools install lynx elinks >> $LOGFILE 2>&1
