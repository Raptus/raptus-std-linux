echo "### Setting up certbot"

### Legacy bot, not recommended anymore
#dnf -y install python3-virtualenv python36-devel augeas-libs libffi-devel >> $LOGFILE 2>&1
#curl -o /usr/local/bin/certbot-auto https://dl.eff.org/certbot-auto >> $LOGFILE 2>&1
#sudo chown root /usr/local/bin/certbot-auto
#chmod 0755 /usr/local/bin/certbot-auto

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