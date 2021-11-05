#!/bin/bash

echo "### Setting up pure-ftpd (disabled per default)"

OLDDIR="`pwd`"
cd /root/scripts/rsl
git pull >> /dev/null
source /root/scripts/rsl/common.inc
dnf -y install pure-ftpd >> $LOGFILE 2>&1

mv /etc/pure-ftpd/pure-ftpd.conf /etc/pure-ftpd/pure-ftpd.conf.ORIG
cp $ADN_PATH/configs-ol/etc-pure-ftpd/pure-ftpd.conf /etc/pure-ftpd/pure-ftpd.conf

touch /etc/pure-ftpd/pureftpd.passwd
chmod u=+rw,go= /etc/pure-ftpd/pureftpd.passwd
pure-pw mkdb

chmod -x /usr/lib/systemd/system/pure-ftpd.service

systemctl disable pure-ftpd >> $LOGFILE 2>&1
echo "### run `systemctl enable pure-ftpd` to enable the service"
