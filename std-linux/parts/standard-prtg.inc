echo "### Setting up prtg sensors"

dnf -y install python3 python3-devel >> $LOGFILE 2>&1
pip3 install psutil >> $LOGFILE 2>&1
alternatives --set python /usr/bin/python3 >> $LOGFILE 2>&1

mkdir -p /var/prtg/scripts
mkdir -p /var/prtg/scriptsxml

PRTG_SCRIPTS=/var/prtg/scripts/
PRTG_SCRIPTSXML=/var/prtg/scriptsxml

getFileFromURL https://bitbucket.org/raptus-it/prtg-linux-sensors/raw/master/scriptsxml/prtg-lemp-stack-check.sh $PRTG_SCRIPTSXML
getFileFromURL https://bitbucket.org/raptus-it/prtg-linux-sensors/raw/master/scriptsxml/prtg-process-monitor.py $PRTG_SCRIPTSXML
getFileFromURL https://bitbucket.org/raptus-it/prtg-linux-sensors/raw/master/scriptsxml/prtg-smartmon-status.sh $PRTG_SCRIPTSXML

getFileFromURL https://bitbucket.org/raptus-it/prtg-linux-sensors/raw/master/scripts/prtg-phpfpm-ping-check.sh $PRTG_SCRIPTS
getFileFromURL https://bitbucket.org/raptus-it/prtg-linux-sensors/raw/master/scripts/prtg-raid-check-adaptec.sh $PRTG_SCRIPTS
getFileFromURL https://bitbucket.org/raptus-it/prtg-linux-sensors/raw/master/scripts/prtg-raid-check-mdraid.sh $PRTG_SCRIPTS
getFileFromURL https://bitbucket.org/raptus-it/prtg-linux-sensors/raw/master/scripts/prtg-raid-check-megaraid.sh $PRTG_SCRIPTS
getFileFromURL https://bitbucket.org/raptus-it/prtg-linux-sensors/raw/master/scripts/prtg-raid-check-smartarray.sh $PRTG_SCRIPTS
getFileFromURL https://bitbucket.org/raptus-it/prtg-linux-sensors/raw/master/scripts/prtg-sshfs-mount-check.sh $PRTG_SCRIPTS

chmod -R 755 $PRTG_SCRIPTSXML
chmod -R 755 $PRTG_SCRIPTS