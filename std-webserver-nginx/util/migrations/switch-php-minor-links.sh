#!/bin/bash

SITE="$1"
if ! test -d /home/sites/$SITE
then
    echo "Sites $SITE does not exist."
    echo "Aborting."
    exit 1
fi

ln -sfT /opt/php56 /home/sites/$SITE/conf/php-cli/php5
ln -sfT /opt/php71 /home/sites/$SITE/conf/php-cli/php7
ln -sfT /opt/php56 /home/sites/$SITE/conf/php-fpm/php5
ln -sfT /opt/php71 /home/sites/$SITE/conf/php-fpm/php7

if test -f /home/sites/$SITE/scripts/php-cli.sh
then
    sed -r -i "s/^PHPBIN=.*$/PHPBIN=\"\/home\/sites\/\$SITE\/conf\/php-cli\/php\$PHPMAJ\/bin\/php\"/g" /home/sites/$SITE/scripts/php-cli.sh
fi

if test -f /home/sites/$SITE/scripts/php-fcp.sh
then
    sed -r -i "s/^PHPBIN=.*$/PHPBIN=\"\/home\/sites\/\$SITE\/conf\/php-fpm\/php\$PHPMAJ\/sbin\/php-fpm\"/g" /home/sites/$SITE/scripts/php-fcp.sh
fi

if test -f /home/sites/$SITE/scripts/php-fpm.sh
then
    sed -r -i "s/^PHPBIN=.*$/PHPBIN=\"\/home\/sites\/\$SITE\/conf\/php-fpm\/php\$PHPMAJ\/sbin\/php-fpm\"/g" /home/sites/$SITE/scripts/php-fpm.sh
fi

