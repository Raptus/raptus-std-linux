echo "### Setting up pure-ftpd"
yum -y install pure-ftpd >> $LOGFILE 

mv /etc/pure-ftpd/pure-ftpd.conf /etc/pure-ftpd/pure-ftpd.conf.ORIG
cp $SCRIPTPATH/std-linux/configs-centos/etc-pure-ftpd/pure-ftpd.conf /etc/pure-ftpd/pure-ftpd.conf

touch /etc/pure-ftpd/pureftpd.passwd
chmod u=+rw,go= /etc/pure-ftpd/pureftpd.passwd
pure-pw mkdb

chmod -x /usr/lib/systemd/system/pure-ftpd.service

systemctl disable pure-ftpd >> $LOGFILE 2>&1
