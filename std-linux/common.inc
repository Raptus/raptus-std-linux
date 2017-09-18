# 
# Defaults & Helpers
#

# Detect distribution
DISTRO=""
if ! test -z "`grep 'ID.*centos' /etc/os-release`"
then
    DISTRO="centos"
    HNFULL="`hostnamectl status | sed -r -n 's/^.*Static hostname: (.*)$/\1/p'`"

fi

DISTRO_NAME="`sed -r -n 's/PRETTY_NAME=\"(.*)\"/\1/p' /etc/os-release`"

if test -z "`echo $0 | grep 'bash'`"
then
    SCRIPT=$(readlink -f $0)
    SCRIPTID=`basename $0 | head -c -4`
    SCRIPTPATH=`dirname $SCRIPT`
else
    SCRIPT="none"
    SCRIPTID="none"
    SCRIPTPATH="/root/scripts/rsl/std-linux"
fi

OUR_IPS=
ADMIN_EMAIL=

APGOPTS="-n1 -m15 -x15 -a0 -q -M NCL"
TEMPDIR="/var/raptus/tmp"
LOCKDIR="/var/raptus/lock"
LOGDIR="/var/raptus/log"
STATEDIR="/var/raptus/state"
LOCKFILE="$LOCKDIR/$SCRIPTID.done"
LOCKFILE_BSTRAP="$LOCKDIR/bootstrap.done"
LOGFILE="$LOGDIR/$SCRIPTID-`date +%Y%m%d-%H%M`.log"
CFGFILE="/root/.rslcfg"
MACHINE_TYPE="physical"
MACHINE_INFO="n/a"

test -d "$TEMPDIR" || { mkdir -p "$TEMPDIR"; }
test -d "$LOCKDIR" || { mkdir -p "$LOCKDIR"; }
test -d "$LOGDIR" || { mkdir -p "$LOGDIR"; }
test -d "$STATEDIR" || { mkdir -p "$STATEDIR"; }

function askConfirmation
{
    echo
    echo "Are you sure? [y/n] "
    read YESNO
    test "$YESNO" = "y" || { echo "Aborted!"; exit 1; }
    echo
}

function checkInstall
{
    if test "$DISTRO" = "centos"
    then
        if test -z "`cat /etc/os-release | grep 'VERSION_ID=\"7\"'`"
        then
            echo "This CentOS Version is not supported. Aborting ..."
            exit 1
        fi
    else
        echo "This Linux distribution is not supported. Aborting ..."
        exit 1
    fi
}

function checkHostname
{
    if ! test "`echo ${HNFULL} | grep -oc '\.'`" = "1"
    then
        echo "The hostname $HNFULL is not set correctly, please use a FQDN."
        exit 1
    fi
}

function checkLockFile
{
    test -d "$LOCKDIR" || { mkdir -p "$LOCKDIR"; chmod go= "$LOCKDIR"; }
    if test -f "$LOCKFILE"
    then
        echo "This script should only be executed once."
        echo "If you want to override that, please follow this procedure:"
        echo 
        echo "1. Know what you are doing!"
        echo "2. Remove the lock file $LOCKFILE"
        exit 1
    fi

    touch "$LOCKFILE"
}

function checkBootstrapped
{
    if ! test -f "$LOCKFILE_BSTRAP"
    then
        echo "Oops, you need to bootstrap first!"
        exit 1
    fi
}

function markAsDone
{
    echo
    echo "Please reboot now, before doing anything with this installation"
    echo

    echo "`date`" > "$LOCKFILE_BSTRAP"
}

#
# Call this function with: <purpose> <username> <password> [address]
#
function passwordInfo
{
    PWDFILE="/root/generated-passwords.txt"
    if ! test -f "$PWDFILE"
    then
        echo "Generated passwords for $SCRIPTID" >> $PWDFILE
        echo "" >> $PWDFILE
        chmod u=+rw,go= $PWDFILE
    fi

    echo "$1  Username: $2  Password: $3     Address: $4" >> $PWDFILE
    echo "    ATTENTON"
    echo "    A Password has been generated for $1, please see in $PWDFILE"
    echo 
}

function htpasswd
{
    file="$1"
    username="$2"
    password="$3"
    printf "${username}:`echo ${password} | openssl passwd -stdin -apr1`\n" >> $file
}

function detectSystem
{
    if test -z "`which virt-what`"
    then
        echo "Cannot find virt-what package."
        exit 1
    fi

    VDETECT="`virt-what | tail -n1`"
    if ! test -z "$VDETECT"
    then
        MACHINE_TYPE="$VDETECT"
        MACHINE_INFO="`virt-what | head -n1`"
    else
        MACHINE_TYPE="physical"
        MACHINE_INFO="`dmidecode -s system-product-name`"
    fi
}

# eof
