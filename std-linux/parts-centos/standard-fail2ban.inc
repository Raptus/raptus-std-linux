echo "### Setting up fail2ban"
yum install fail2ban -y >> $LOGFILE

mv /etc/fail2ban/jail.d/00-firewalld.conf /etc/fail2ban/jail.d/00-firewalld.conf.ORIG
cp $SCRIPTPATH/configs-centos/etc-fail2ban/* /etc/fail2ban/jail.d/

systemctl enable fail2ban.service >> $LOGFILE 2>&1
systemctl restart fail2ban.service >> $LOGFILE 2>&1
