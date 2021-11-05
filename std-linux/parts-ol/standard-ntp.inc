echo "### Setting up ntp"
dnf -y install chrony >> $LOGFILE 2>&1
sed -i '/pool 2.ol.pool.ntp.org iburst/c\pool ch.pool.ntp.org iburst' /etc/chrony.conf
systemctl restart chronyd >> $LOGFILE 2>&1
