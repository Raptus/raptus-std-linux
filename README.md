# README #

### What is this for? ###

* Simple Standard Linux Installation
* WebStack with Nginx, PHP, MariaDB

### Install Step 1 - AZURE Virtual Machine ###
* Choose Oracle Linux v9 Template
* Resize OS-Disk according to concept
* Resize Partition and Filesystem in System
```shell
growpart /dev/sda 2
pvresize /dev/sda2
lvresize -l 100%FREE /dev/rootvg/rootlv
xfs_growfs /dev/mapper/rootvg-rootlv
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
Create/edit the configuration file (Azure: do not activate the firewall just yet)
```shell
echo "OUR_IPS=1.2.3.4,11.22.33.44" > /root/.rslcfg
echo "ADMIN_EMAIL=myname@domain.tld" >> /root/.rslcfg
echo "ENABLE_FIREWALL="no" >> /root/.rslcfg
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

### Install Step 3.1 - Azure Only: ###
Remove the IP restrictions in the Shorewall configuration and activate the firewall. IP restrictions have to be managed by NSG in Azure.

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
dnf -y config-manager --set-enabled ol9_codeready_builder
dnf -y install sshfs fuse-sshfs
```
---
If you need subversion, run:
```shell
dnf -y config-manager --set-enabled ol9_codeready_builder
dnf -y install subversion subversion-tools
```
---
If you need additional PHP version, run:
```shell
/root/scripts/rsl/std-webserver-nginx/util/install-php.sh phpvers
```
Then change the symlinks php binaries in your site
