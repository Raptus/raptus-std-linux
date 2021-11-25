echo "### Setting up certbot"

OLDDIR="`pwd`"
cd /root/scripts/rsl
git pull >> /dev/null
source /root/scripts/rsl/common.inc

dnf -y install snapd
systemctl enable --now snapd.socket
systemctl start snapd
ln -s /var/lib/snapd/snap /snap

snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot

echo ""
echo "You can now use the certbot command"
echo ""

#eof