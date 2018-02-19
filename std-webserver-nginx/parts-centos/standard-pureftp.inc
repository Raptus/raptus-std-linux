echo "### Setting up pure-ftpd (disabled per default)"
yum -y install pure-ftpd >> $LOGFILE 2>&1

mv /etc/pure-ftpd/pure-ftpd.conf /etc/pure-ftpd/pure-ftpd.conf.ORIG
cp $WEB_PATH/configs-centos/etc-pure-ftpd/pure-ftpd.conf /etc/pure-ftpd/pure-ftpd.conf

touch /etc/pure-ftpd/pureftpd.passwd
chmod u=+rw,go= /etc/pure-ftpd/pureftpd.passwd
pure-pw mkdb

chmod -x /usr/lib/systemd/system/pure-ftpd.service

systemctl disable pure-ftpd >> $LOGFILE 2>&1
