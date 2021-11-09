echo "### Setting up certbot"

OLDDIR="`pwd`"
cd /root/scripts/rsl
git pull >> /dev/null
source /root/scripts/rsl/common.inc

dnf -y install snapd >> $LOGFILE 2>&1
systemctl enable --now snapd.socket >> $LOGFILE 2>&1
ln -s /var/lib/snapd/snap /snap

snap install --classic certbot >> $LOGFILE 2>&1
ln -s /snap/bin/certbot /usr/bin/certbot

echo "Please reboot now, before doing anything with this system"

#eof