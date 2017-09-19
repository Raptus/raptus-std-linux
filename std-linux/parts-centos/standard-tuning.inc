echo "### Tuning system"

cp $SCRIPTPATH/configs-centos/etc-sysctl.d/rsl-defaults.conf /etc/sysctl.d/rsl-defaults.conf
echo "$SCRIPTPATH/util/network-tuning.sh" >> /etc/rc.local
