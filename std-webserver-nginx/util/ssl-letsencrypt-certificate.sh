#!/bin/bash

ACMEACCOUNT="hostmaster@raptus.com"

if test -z "$1"
then
    echo "Usage: $0 <domain.tld>"
    echo 
    exit 1
fi

SITE="$1"
if ! test -d "/home/sites/$SITE"
then
    echo "Cannot find site $SITE"
    exit 2
fi

if test -z "`yum list installed | grep certbot-nginx`"
then
    echo "FATAL: Missing package 'certbot-nginx'"
    exit 3
fi

certbot --nginx certonly --agree-tos -n -m "$ACMEACCOUNT" -d "$SITE"

if ! test -f /etc/letsencrypt/live/$SITE/fullchain.pem &&
   ! test -f /etc/letsencrypt/live/$SITE/privkey.pem
then
    echo "Cannot find valid certificate. Aborting."
    exit 4
fi

ln -sf /etc/letsencrypt/live/$SITE/fullchain.pem /home/sites/$SITE/ssl/package.pem
ln -sf /etc/letsencrypt/live/$SITE/privkey.pem /home/sites/$SITE/ssl/private.key

nginx -t >/dev/null 2>&1
if ! test "$?" = "0"
then
    echo "Nginx configuration is not ok. Aborting."
    exit 5
fi

systemctl reload nginx

if test -z "`grep 'certbot renew --post-hook' /etc/crontab`"
then
    echo "### Certbot" >> /etc/crontab
    echo "00    23   * * *   root    certbot renew --post-hook \"systemctl reload nginx\" >> /var/log/certbot.log 2>&1" >> /etc/crontab
    echo . >> /etc/crontab
    echo "# eof" >> /etc/crontab
fi

# eof