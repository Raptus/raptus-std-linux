#BFS="`apg -a0 -m15 -x15 -d -M NCL`"
#sed -i -r "s/INSERT_HERE_GENERATED_BLOWFISH_SECRET/$BFS/g" /home/ADMIN-SITE/pub/httpdocs/admin/phpmyadmin/config.inc.php


usermod -s /bin/bash s_testix.zurigos.local
sudo -u s_testix.zurigos.local /home/sites/testix.zurigos.local/scripts/php-cli.sh /opt/composer/bin/composer create-project phpmyadmin/phpmyadmin /home/sites/testix.zurigos.local/pub/httpdocs/admin/
