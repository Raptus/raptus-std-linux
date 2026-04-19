#!/bin/bash

echo "### Initializing package repositories"
dnf -y config-manager --set-enabled crb >> $LOGFILE 2>&1
dnf -y config-manager --enable appstream >> $LOGFILE 2>&1
dnf -y install epel-release >> $LOGFILE 2>&1
dnf -y clean all >> $LOGFILE 2>&1

echo "### Installing base packages"
dnf -y upgrade >> $LOGFILE 2>&1
dnf -y update ca-certificates >> $LOGFILE 2>&1
dnf -y groupinstall 'Development Tools' >> $LOGFILE 2>&1
PYTHON_DEVEL="platform-python-devel"
if test "$ROCKY_MAJOR" = "10"
then
    PYTHON_DEVEL="python3-devel"
fi

dnf -y install acpid bzip2 pwgen bind-utils ghostscript htop nano nmap nload cifs-utils \
               net-tools nfs-utils psmisc $PYTHON_DEVEL rsync screen tmux ftp \
               symlinks telnet traceroute tree unzip dnf-utils sysstat vim vim-common \
               wget whois readline-devel openssl-devel bash-completion pciutils virt-what >> $LOGFILE 2>&1

echo "### Setting up environment"
yes | cp $STD_PATH/configs/.bashrc /root/
yes | cp $STD_PATH/configs/.screenrc /root/
yes | cp $STD_PATH/configs/.vimrc /root/
yes | cp $STD_PATH/configs/.tmux.conf /root/
touch /root/.bashrc_local
mkdir /root/{dist,build,temp}

source $STD_PATH/parts/standard-security.inc
source $STD_PATH/parts/standard-ssh.inc
source $STD_PATH/parts/standard-cron.inc
source $STD_PATH/parts/standard-ntp.inc
source $STD_PATH/parts/standard-postfix.inc
source $STD_PATH/parts/standard-snmp.inc
source $STD_PATH/parts/standard-fstrim.inc
source $STD_PATH/parts/standard-sysdefaults.inc
source $STD_PATH/parts/standard-tuning.inc

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
if test -f "$STD_PATH/parts/machine-$MACHINE_TYPE.inc"
then
    source $STD_PATH/parts/machine-$MACHINE_TYPE.inc
fi

#eof
