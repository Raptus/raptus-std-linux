#!/bin/bash
#UNTESTED!
source /root/scripts/rsl/common.inc

if test -z "$1" || test -z "$2"
then
    echo "Usage: $0 <domain.tld> <acme_account_email>"
    echo
    exit 1
fi

SITE="$1"
ACMEACCOUNT="$2"
if ! test -d "/home/sites/$SITE"
then
    echo "Cannot find site $SITE"
    exit 2
fi

/usr/local/bin/certbot-auto certonly --webroot --webroot-path /home/sites/$SITE/pub/httpdocs -d $SITE -m $ACMEACCOUNT --agree-tos

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

if test -z "`grep '/usr/local/bin/certbot-auto renew -q' /etc/crontab`"
then
    echo "### Certbot" >> /etc/crontab
    echo "0 0,12 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && /usr/local/bin/certbot-auto renew -q >> /var/log/certbot.log 2>&1" >> /etc/crontab
    echo . >> /etc/crontab
    echo "# eof" >> /etc/crontab
fi

# eof
