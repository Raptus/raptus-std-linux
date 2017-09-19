echo "### Tuning system"

cp $SCRIPTPATH/configs-centos/etc-sysctl.d/rsl-defaults.conf /etc/sysctl.d/rsl-defaults.conf
echo "$SCRIPTPATH/util/network-tuning.sh" >> /etc/rc.local
echo "$SCRIPTPATH/util/rebuild-initramfs-once.sh" >> /etc/rc.local

systemctl disable rpcbind.service >> $LOGFILE 2>&1