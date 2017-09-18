echo "### Tuning system"

cp $SCRIPTPATH/configs-centos/etc-sysctl.d/raptus-defaults.conf /etc/sysctl.d/raptus-defaults.conf
echo "$SCRIPTPATH/util/network-tuning.sh" >> /etc/rc.local
