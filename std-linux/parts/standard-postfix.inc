echo "### Setting up postfix"

# Needed for smtp auth
dnf -y install postfix cyrus-sasl-plain postfix-lmdb >> $LOGFILE 2>&1

mv /etc/postfix/main.cf /etc/postfix/main.cf.ORIG
cp $STD_PATH/configs/etc-postfix/main.cf /etc/postfix/main.cf

mv /etc/aliases /etc/aliases.ORIG
cat > /etc/aliases << EOF
# See man 5 aliases for format
postmaster:    root
root:          $ADMIN_EMAIL
EOF

newaliases
cd /etc/postfix
ln -s ../aliases

systemctl enable postfix >> $LOGFILE 2>&1

# eof
