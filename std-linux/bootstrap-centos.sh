#!/bin/bash

echo "### Initializing package repositories"
yum -y install epel-release >> $LOGFILE 2>&1
yum -y clean all >> $LOGFILE 2>&1

echo "### Installing base packages"
yum -y install deltarpm >> $LOGFILE 2>&1
yum -y upgrade >> $LOGFILE 2>&1
yum -y update ca-certificates >> $LOGFILE 2>&1
yum -y remove NetworkManager >> $LOGFILE 2>&1
yum -y groupinstall 'Development Tools' >> $LOGFILE 2>&1
yum -y install acpid apg bzip2 bind-utils bonnie++ ftp ghostscript git nano nmap nload net-tools \
               nfs-utils psmisc python-devel rsync screen subversion subversion-tools symlinks \
               tcpdump tcpdump telnet traceroute tree unhide unrtf unzip uuid vim-vimoutliner \
               w3m wget whois readline-devel openssl-devel bash-completion pciutils virt-what \
               sshfs yum-utils sysstat >> $LOGFILE 2>&1

echo "### Setting up environment"
if test -d /home/radmin
then
	cp $SCRIPTPATH/configs-centos/.bashrc /home/radmin/
	cp $SCRIPTPATH/configs-centos/.screenrc /home/radmin/
	cp $SCRIPTPATH/configs-centos/.vimrc /home/radmin/
    chown radmin:radmin /home/radmin
fi

cp $SCRIPTPATH/configs-centos/.bashrc /root/
cp $SCRIPTPATH/configs-centos/.screenrc /root/
cp $SCRIPTPATH/configs-centos/.vimrc /root/
touch /root/.bashrc_local
mkdir /root/{dist,build,temp}

source $SCRIPTPATH/parts-centos/standard-security.inc
source $SCRIPTPATH/parts-centos/standard-ssh.inc
source $SCRIPTPATH/parts-centos/standard-cron.inc
source $SCRIPTPATH/parts-centos/standard-ntp.inc
source $SCRIPTPATH/parts-centos/standard-postfix.inc
source $SCRIPTPATH/parts-centos/standard-snmp.inc
source $SCRIPTPATH/parts-centos/standard-prtg.inc
source $SCRIPTPATH/parts-centos/standard-fstrim.inc
source $SCRIPTPATH/parts-centos/standard-sysdefaults.inc
source $SCRIPTPATH/parts-centos/standard-fail2ban.inc
source $SCRIPTPATH/parts-centos/standard-shorewall.inc
source $SCRIPTPATH/parts-centos/standard-tuning.inc

echo "### Enabling services"
systemctl enable acpid.service >> $LOGFILE 2>&1
chmod +x /etc/rc.local

echo "### Disabling services"
systemctl disable kdump.service >> $LOGFILE 2>&1
systemctl disable nfs-client.target >> $LOGFILE 2>&1
systemctl disable nfs-config.service >> $LOGFILE 2>&1
systemctl disable gssproxy.service >> $LOGFILE 2>&1

yum -y remove polkit polkit-pkla-compat >> $LOGFILE 2>&1
chmod o=+r /usr/lib/systemd/system/auditd.service
chmod -x /usr/lib/systemd/system/ebtables.service
chmod -x /usr/lib/systemd/system/wpa_supplicant.service

detectSystem
echo "### Detected machine type: $MACHINE_TYPE / $MACHINE_INFO"
if test -f "$SCRIPTPATH/parts-centos/machine-$MACHINE_TYPE.inc"
then
    source $SCRIPTPATH/parts-centos/machine-$MACHINE_TYPE.inc
fi

#eof