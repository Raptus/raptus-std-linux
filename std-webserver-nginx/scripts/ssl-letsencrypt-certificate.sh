#!/bin/bash
#UNTESTED!
source /root/scripts/rsl/common.inc

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

certbot certonly --nginx --register-unsafely-without-email --agree-tos -d $SITE

if ! test -f /etc/letsencrypt/live/$SITE/fullchain.pem &&
   ! test -f /etc/letsencrypt/live/$SITE/privkey.pem
then
    echo "Cannot find valid certificate. Aborting." >>/dev/stderr
    exit 4
fi

ln -sf /etc/letsencrypt/live/$SITE/fullchain.pem /home/sites/$SITE/ssl/package.pem
ln -sf /etc/letsencrypt/live/$SITE/privkey.pem /home/sites/$SITE/ssl/private.key

nginx -t >> $LOGFILE 2>&1
if ! test "$?" = "0"
then
    echo "Nginx configuration is not ok. Aborting." >>/dev/stderr
    exit 5
fi

systemctl reload nginx

if test -z "`grep 'certbot renew' /etc/crontab`"
then
    echo "" >> /etc/crontab
    echo "### Certbot" >> /etc/crontab
    echo "00    23   * * *   root    certbot renew --post-hook "systemctl reload nginx" >> /var/log/certbot.log 2>&1" >> /etc/crontab
    echo . >> /etc/crontab
    echo "# eof" >> /etc/crontab
fi

# eof
