# README #

### What is this for? ###

* Simple Standard Linux Installation
* WebStack with Nginx, PHP, MariaDB

#### NOTE: This Bootstrapper is maintaned for Rocky Linux. Look for other Linux distros in other branches. Beware: the other branches are usally not maintained. ####

### Install Step 1 - AZURE Virtual Machine ###
* Choose **Rocky Linux 9** Template
      * Azure Marketplace Name: (Rocky Linux for x86_64 (AMD64) - Official)[https://azuremarketplace.microsoft.com/en-us/marketplace/apps/resf.rockylinux-x86_64?tab=PlansAndPrice]
* Resize OS-Disk according to concept
* There might be an LVM bug in RL9, workaround with the following:
```shell
sed -i 's/# use_devicesfile = 0/use_devicesfile = 0/g' /etc/lvm/lvm.conf
```
* Resize Partition and Filesystem in System
```shell
growpart /dev/sda 5
pvresize /dev/sda5
lvresize -l 100%FREE /dev/rocky/root
xfs_growfs /dev/mapper/rocky-root
```
* Swapfile: Change Size of swapfile according to your needs
```shell
touch /var/lib/cloud/scripts/per-boot/create_swapfile.sh
chmod +x /var/lib/cloud/scripts/per-boot/create_swapfile.sh

cat > /var/lib/cloud/scripts/per-boot/create_swapfile.sh << EOF
#!/bin/sh
if [ ! -f '/mnt/swapfile' ]; then
fallocate --length 4GiB /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile
swapon /mnt/swapfile
swapon -a 
else
swapon /mnt/swapfile; fi
EOF
```

### Install Step 2 ###
Set hostname if not already configured
```shell
hostnamectl set-hostname hostname.domain.tld 
```
Set admin e-mail (usually "report.hosting-info@raptus.com")
```shell
echo "ADMIN_EMAIL=myname@domain.tld" >> /root/.rslcfg 
```

### Install Step 3: ###
Kickstart the installation
```shell
bash <(curl -s https://bitbucket.org/raptus-it/raptus-std-linux/raw/master/kickstart-standard-linux.sh)
```

### Install Step 4: ###
Do now secure the vm with new [Raptus security standards](https://bitbucket.org/raptus-it/raptus-linux-access/src/master/)

### Additional Steps: ###
If this will be a webserver, run:
```shell
/root/scripts/rsl/std-webserver-nginx/standard-webserver.sh
```
If this will be an upstream proxy only, run:
```shell
/root/scripts/rsl/std-upstream-proxy-nginx/standard-webproxy.sh
```

### OPTIONAL Additional Installations Steps: ###
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
/root/scripts/rsl/std-webserver-nginx/scripts/ssl-letsencrypt-certificate.sh
```
---
If you need command line based browsers, run:
```shell
dnf -y install lynx elinks
```
---
If you need additional PHP version, run:
```shell
/root/scripts/rsl/std-webserver-nginx/util/install-php.sh phpvers
```
Then change the symlinks php binaries in your site
