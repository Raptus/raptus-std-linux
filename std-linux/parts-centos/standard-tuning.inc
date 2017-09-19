echo "### Tuning system"

cp $SCRIPTPATH/configs-centos/etc-sysctl.d/rsl-defaults.conf /etc/sysctl.d/rsl-defaults.conf
echo "$SCRIPTPATH/util/network-tuning.sh" >> /etc/rc.local

# Need to rebuild initram FS due to changes of sysctl
sysctl -p
dracut -v -f >> $LOGFILE 2>&1