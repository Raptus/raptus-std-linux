echo "### Installing base packages"

dnf -y install freeglut geoip geoipupdate mailx ImageMagick ImageMagick-devel libyaml-devel \
               freetype freetype-devel gd gd-devel libjpeg-turbo-static libjpeg-turbo-devel\
               libxml2-devel libxslt-devel optipng pngquant poppler-utils >> $LOGFILE 2>&1

#eof