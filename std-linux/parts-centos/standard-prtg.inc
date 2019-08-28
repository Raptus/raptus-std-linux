echo "### Setting up prtg sensors"
yum -y install python-psutil >> $LOGFILE 2>&1

mkdir -p /var/prtg/scripts
mkdir -p /var/prtg/scriptsxml

PRTG_SCRIPTS=/var/prtg/scripts/
PRTG_SCRIPTSXML=/var/prtg/scriptsxml

getFileFromURL https://bitbucket.org/raptus-it-services/prtg-linux-sensors/raw/master/scriptsxml/prtg-lemp-stack-check.sh $PRTG_SCRIPTSXML
getFileFromURL https://bitbucket.org/raptus-it-services/prtg-linux-sensors/raw/master/scriptsxml/process-monitor.py $PRTG_SCRIPTSXML
getFileFromURL https://bitbucket.org/raptus-it-services/prtg-linux-sensors/raw/master/scriptsxml/scriptsxml/smartmontools.sh $PRTG_SCRIPTSXML

getFileFromURL https://bitbucket.org/raptus-it-services/prtg-linux-sensors/raw/master/scripts/phpfpm-ping-check.sh $PRTG_SCRIPTS
getFileFromURL https://bitbucket.org/raptus-it-services/prtg-linux-sensors/raw/master/scripts/sshfs-mount-check.sh $PRTG_SCRIPTS
getFileFromURL https://bitbucket.org/raptus-it-services/prtg-linux-sensors/raw/master/scripts/raid-check-mdraid.sh $PRTG_SCRIPTS
getFileFromURL https://bitbucket.org/raptus-it-services/prtg-linux-sensors/raw/master/scripts/raid-check-smartarray.sh $PRTG_SCRIPTS

chmod -R 755 $PRTG_SCRIPTSXML
chmod -R 755 $PRTG_SCRIPTS