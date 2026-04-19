echo "### Setting up nginx"

DIST=rhel
NGINX_OSRELEASE="$ROCKY_MAJOR"
NGINX_BASEARCH="x86_64"

cat > /etc/yum.repos.d/nginx.repo << EOF
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/$DIST/$NGINX_OSRELEASE/$NGINX_BASEARCH/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
EOF

# Need to build from source, since no loadable module support yet
dnf -y install nginx certbot python3-certbot-nginx >> $LOGFILE 2>&1

mv /etc/nginx /etc/nginx.ORIG
cp -R $WEB_PATH/configs/etc-nginx /etc/nginx
mkdir -p /etc/nginx/sites-enabled
sed -r -i "s/(.*)HOSTMASTER(.*)$/\1$ADMIN_EMAIL\2/g" /etc/nginx/fastcgi_params

echo "### Our IP List"                    >> /etc/nginx/conf.d/global-maps.conf
echo "map \$remote_addr \$not-our-ips {"  >> /etc/nginx/conf.d/global-maps.conf
echo "default 1;"                         >> /etc/nginx/conf.d/global-maps.conf
for oip in $OUR_IPS_SPACED
do
    echo "$oip 0;" >> /etc/nginx/conf.d/global-maps.conf
done
echo "}" >> /etc/nginx/conf.d/global-maps.conf
echo >> /etc/nginx/conf.d/global-maps.conf

cp $WEB_PATH/configs/etc-logrotate.d/nginx /etc/logrotate.d/nginx

# generate a stronger DHE parameter
# Using -dsaparam to speedup. See this for more information:
# https://security.stackexchange.com/questions/95178/diffie-hellman-parameters-still-calculating-after-24-hours
openssl dhparam -dsaparam -out /etc/nginx/dhparam.pem 4096 >> $LOGFILE 2>&1

systemctl enable nginx.service >> $LOGFILE 2>&1
systemctl start nginx.service >> $LOGFILE 2>&1

# eof
