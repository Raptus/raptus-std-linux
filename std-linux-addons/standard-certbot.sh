echo "### Setting up certbot"

OLDDIR="`pwd`"
cd /root/scripts/rsl
git pull >> /dev/null
source /root/scripts/rsl/common.inc

dnf -y install snapd
systemctl enable --now snapd.socket
ln -s /var/lib/snapd/snap /snap

snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

echo ""
echo "Please reboot now, before doing anything with this system"
echo ""

#eof