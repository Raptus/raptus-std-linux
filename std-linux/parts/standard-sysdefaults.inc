echo "### Setting up system defaults"

dnf -y install dnf-automatic >> $LOGFILE 2>&1
systemctl enable --now dnf-automatic.timer >> $LOGFILE 2>&1

sed -i -r "s/(^emit_via = )stdio/\1email/g" /etc/dnf/automatic.conf
sed -i -r "s/(^email_from = ).*$/\1$ADMIN_EMAIL/g" /etc/dnf/automatic.conf

sed -i -r "s/(^GRUB_TIMEOUT=).*/\13/g" /etc/default/grub
grub2-mkconfig >> $LOGFILE 2>&1

sed -i -r "s/(^CREATE_MAIL_SPOOL=).*/\1no/g" /etc/default/useradd
