echo "### Setting up memcached (disabled per default)"
dnf -y install memcached libmemcached python3-memcached >> $LOGFILE 2>&1

sed -i -r "s/(^CACHESIZE=\").*(\")/\1128\2/g" /etc/sysconfig/memcached

systemctl disable memcached >> $LOGFILE 2>&1

# eof
