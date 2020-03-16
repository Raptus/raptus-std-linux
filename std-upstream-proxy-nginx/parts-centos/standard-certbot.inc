echo "### Setting up certbot"

curl -o /usr/local/bin/certbot-auto https://dl.eff.org/certbot-auto >> $LOGFILE 2>&1
sudo chown root /usr/local/bin/certbot-auto
chmod 0755 /usr/local/bin/certbot-auto
