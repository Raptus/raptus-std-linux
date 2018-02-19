echo "### Installing base packages"

yum -y install freeglut html2ps html2text htmldoc GeoIP GeoIP-update.noarch lynx mailx \
               ImageMagick ImageMagick-devel freetype freetype-devel gd gd-devel \
               libjpeg-turbo-static libjpeg-turbo-devel libxml2-devel libxslt-devel \
               libyaml-devel certbot-nginx \
               optipng pngnq pngquant poppler-utils ruby w3m >> $LOGFILE 2>&1
