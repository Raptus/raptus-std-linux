echo "### Setting up shorewall"
yum install shorewall fail2ban-shorewall -y >> $LOGFILE

cp $SCRIPTPATH/configs-centos/etc-shorewall/* /etc/shorewall/

sed -i 's/STARTUP_ENABLED=No/STARTUP_ENABLED=yes/' /etc/shorewall/shorewall.conf >> $LOGFILE
sed -i '$ a net         eth0            routefilter,tcpflags,logmartians' /etc/shorewall/interfaces >> $LOGFILE

IP=`hostname -I`
sed -i "s/PRIMARYIP=/PRIMARYIP=$IP/" /etc/shorewall/params >> $LOGFILE
sed -i "s/OURIPS=/OURIPS=$OUR_IPS/" /etc/shorewall/params >> $LOGFILE

echo -e "\
shorewall.conf\n\
blrules\n\
conntrack\n\
hosts\n\
interfaces\n\
lib.private\n\
Makefile\n\
params\n\
policy\n\
rules\n\
scfilter\n\
zones\
" > /tmp/shorewall-excludes

rsync --exclude-from '/tmp/shorewall-excludes' -a --remove-source-files /etc/shorewall/ /etc/shorewall/OTHERMODULES >> $LOGFILE
rm /tmp/shorewall-excludes

systemctl disable firewalld.service >> $LOGFILE 2>&1
systemctl enable shorewall.service >> $LOGFILE 2>&1

echo "30    1    * * *   root    /usr/sbin/shorewall restart" >> /etc/crontab
