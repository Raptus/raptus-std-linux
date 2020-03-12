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
    echo "### Installing GIT"
    dnf -y install git uuid > /dev/null 2>&1
else
    echo "Linux distribution not supported."
    exit 1
fi

echo "### Checking out from GIT"
test -d "/root/scripts" || mkdir -p /root/scripts
if ! test -d /root/scripts/rsl/.git
then
    git clone --depth 1 https://bitbucket.org/raptus-it/raptus-std-linux.git /root/scripts/rsl
fi

if test -f "/root/scripts/rsl/std-linux/bootstrap.sh"
then
	/root/scripts/rsl/std-linux/bootstrap.sh
else
    echo "Cannot find bootstrap file. Aborting."
    exit 1
fi

# eof
