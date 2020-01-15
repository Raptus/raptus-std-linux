# README #

### What is this for? ###

* Simple Standard Linux Installation
* WebStack with Nginx, PHP, MariaDB

### Install Step 1 ###
* Install CentOS v7
* Use CentOS minimal Installer
* Make sure Keyboard, Date, Time and NTP is working
* Disable security policies
* Disable kdump

### Install Step 2 ###
Create/edit the configuration file
```shell
echo "OUR_IPS=1.2.3.4,11.22.33.44" > /root/.rslcfg
echo "ADMIN_EMAIL=myname@domain.tld" >> /root/.rslcfg
echo "ENABLE_FIREWALL=yes" >> /root/.rslcfg
```

### Install Step 3: ###
Kickstart the installation
```shell
bash <(curl -s https://bitbucket.org/raptus-it/raptus-std-linux/raw/master/kickstart-standard-linux.sh)
```

### Install Step 4: ###
If this should be a WebServer run
```/root/scripts/rsl/std-webserver-nginx/standard-webserver.sh```

