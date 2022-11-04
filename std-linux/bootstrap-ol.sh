#!/bin/bash

echo "### Initializing package repositories"
dnf -y install oracle-epel-release-el9  >> $LOGFILE 2>&1
dnf -y config-manager --enable ol9_appstream  >> $LOGFILE 2>&1
dnf -y clean all >> $LOGFILE 2>&1

echo "### Installing base packages"
dnf -y upgrade >> $LOGFILE 2>&1
dnf -y update ca-certificates >> $LOGFILE 2>&1
dnf -y groupinstall 'Development Tools' >> $LOGFILE 2>&1
dnf -y install acpid pwgen bzip2 bind-utils ghostscript htop nano nmap nload \
               net-tools nfs-utils psmisc platform-python-devel rsync screen ftp \
               symlinks telnet traceroute tree unzip dnf-utils sysstat vim vim-common \
               wget whois readline-devel openssl-devel bash-completion pciutils virt-what >> $LOGFILE 2>&1

echo "### Setting up environment"
yes | cp $STD_PATH/configs-ol/.bashrc /root/
yes | cp $STD_PATH/configs-ol/.screenrc /root/
yes | cp $STD_PATH/configs-ol/.vimrc /root/
touch /root/.bashrc_local
mkdir /root/{dist,build,temp}

source $STD_PATH/parts-ol/standard-security.inc
source $STD_PATH/parts-ol/standard-ssh.inc
source $STD_PATH/parts-ol/standard-cron.inc
source $STD_PATH/parts-ol/standard-ntp.inc
source $STD_PATH/parts-ol/standard-postfix.inc
source $STD_PATH/parts-ol/standard-snmp.inc
source $STD_PATH/parts-ol/standard-prtg.inc
source $STD_PATH/parts-ol/standard-fstrim.inc
source $STD_PATH/parts-ol/standard-sysdefaults.inc
source $STD_PATH/parts-ol/standard-tuning.inc

echo "### Setting up services"
chmod +x /etc/rc.local
systemctl enable acpid.service >> $LOGFILE 2>&1
systemctl disable kdump.service >> $LOGFILE 2>&1
systemctl disable nfs-client.target >> $LOGFILE 2>&1
systemctl disable gssproxy.service >> $LOGFILE 2>&1
systemctl disable firewalld.service >> $LOGFILE 2>&1

dnf -y remove polkit polkit-pkla-compat >> $LOGFILE 2>&1
chmod o=+r /usr/lib/systemd/system/auditd.service

detectSystem
echo "### Detected machine type: $MACHINE_TYPE / $MACHINE_INFO"
if test -f "$STD_PATH/parts-ol/machine-$MACHINE_TYPE.inc"
then
    source $STD_PATH/parts-ol/machine-$MACHINE_TYPE.inc
fi

#eof
