echo "### Setting up memcached (disabled per default)"
yum -y install memcached libmemcached python-memcached >> $LOGFILE

sed -i -r "s/(^CACHESIZE=\").*(\")/\1128\2/g" /etc/sysconfig/memcached

systemctl disable memcached >> $LOGFILE 2>&1
