# README #

### What is this for? ###

* Simple Standard Linux Installation
* WebStack with Nginx, PHP, MariaDB

### Install Step 0 - Legacy Virtual Machine ###
* Install Oracle Linux v8
* Use [Oracle Linux Boot ISO](https://yum.oracle.com/oracle-linux-isos.html) minimal Installer
* Main installation source: https://yum.oracle.com/repo/OracleLinux/OL8/baseos/latest/x86_64
* Make sure Keyboard, Date, Time and NTP is working
* Create a 2 GiB boot partition for snapshot reasons
* * Use UEFI when possible (not in VDC)
* Disable security policies
* Disable kdump
* Set a hostname in FQDN format

### Install Step 1 - Azure Virtual Machine ###
* Choose Oracle Linux v8 Template
* Resize OS-Disk according to concept
* Resize Partition and Filesystem in System
```shell
growpart /dev/sda 2
pvresize /dev/sda2
lvresize -l 100%FREE /dev/rootvg/rootlv
xfs_growfs /dev/mapper/rootvg-rootlv
```

### Install Step 2 ###
Create/edit the configuration file
```shell
echo "OUR_IPS=1.2.3.4,11.22.33.44" > /root/.rslcfg
echo "ADMIN_EMAIL=myname@domain.tld" >> /root/.rslcfg
echo "ENABLE_FIREWALL=yes" >> /root/.rslcfg
```
Set hostname if not already configured
```shell
hostnamectl set-hostname hostname.domain.tld 
```

### Install Step 3: ###
Kickstart the installation
```shell
bash <(curl -s https://bitbucket.org/raptus-it/raptus-std-linux/raw/master/kickstart-standard-linux.sh)
```

### Install Step 4: ###
If this will be a webserver, run:
```shell
/root/scripts/rsl/std-webserver-nginx/standard-webserver.sh
```
If this will be an upstream proxy only, run:
```shell
/root/scripts/rsl/std-upstream-proxy-nginx/standard-webproxy.sh
```

### OPTIONAL Installations Step 4: ###
If you need FTP server, run:
```shell
/root/scripts/rsl/std-linux-addons/standard-pureftp.sh
```
---
If you need Certbot, for Let's Encrypt certificates, run:
```shell
/root/scripts/rsl/std-linux-addons/standard-certbot.sh
```
---
If you want to use Let's Encrypt for a site, use:
```shell
/root/scripts/rsl/std-webserver-nginx/ssl-letsencrypt-certificate.sh
```
---
If you need command line based browsers, run:
```shell
dnf -y install lynx elinks
```
---
If you need sshfs, run:
```shell
dnf -y install sshfs fuse-sshfs
```
---
If you need subversion, run:
```shell
dnf -y install subversion subversion-tools
```
---
If you need additional PHP version, run:
```shell
/root/scripts/rsl/std-webserver-nginx/util/install-php.sh phpvers
```
Then change the symlinks php binaries in your site
