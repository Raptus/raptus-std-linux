#!/bin/bash

test `whoami` == root || { echo "You need to be root!"; exit 1; }

DISTRO=""
if ! test -z "`grep 'ID.*centos' /etc/os-release`"
then
    export DISTRO="centos"
fi

export DISTRO_NAME="`sed -r -n 's/PRETTY_NAME=\"(.*)\"/\1/p' /etc/os-release`"

echo 
echo "### Kickstarting $DISTRO_NAME"
echo

if test "$DISTRO" = "centos"
then
    yum -y install git > /dev/null 2>&1
else
    echo "Linux distribution not supported."
    exit 1
fi

test -d "/root/scripts" || mkdir -p /root/scripts
git clone --depth 1 https://bitbucket.org/raptus-it-services/raptus-std-linux.git /root/scripts/rsl > /dev/null 2>&1

if test -f "/root/scripts/rsl/std-linux/bootstrap.sh" 
then
	#/root/scripts/rsl/std-linux/bootstrap.sh
	echo "Inst"
else
    echo "Cannot find bootstrap file. Aborting."
    exit 1
fi

# eof