echo "### Setting up fail2ban"
yum install fail2ban -y >> $LOGFILE

mv /etc/fail2ban/jail.d/00-firewalld.conf /etc/fail2ban/jail.d/00-firewalld.conf.ORIG
cp $SCRIPTPATH/configs-centos/etc-fail2ban/* /etc/fail2ban/jail.d/
sed -r -i "s/(.*)OUR_IPS_HERE(.*)$/\1$OUR_IPS_SPACED\2/g" /etc/fail2ban/jail.d/01-jail.conf

systemctl enable fail2ban.service >> $LOGFILE 2>&1
systemctl restart fail2ban.service >> $LOGFILE 2>&1
