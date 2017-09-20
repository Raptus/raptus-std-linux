echo "### Setting up prtg sensors"
yum -y install python-psutil >> $LOGFILE 2>&1

mkdir -p /var/prtg/scripts
mkdir -p /var/prtg/scriptsxml

PRTG_SCRIPTS=/var/prtg/scripts/
PRTG_SCRIPTSXML=/var/prtg/scriptsxml

getFileFromURL https://bitbucket.org/raptus-it-services/prtg-process-sensor/raw/master/process-monitor.py $PRTG_SCRIPTSXML

getFileFromURL https://bitbucket.org/raptus-it-services/prtg-lemp-stack-sensor/raw/master/lemp-stack-check.sh $PRTG_SCRIPTSXML

getFileFromURL https://bitbucket.org/raptus-it-services/prtg-lemp-stack-sensor/raw/master/phpfpm-ping-check.sh $PRTG_SCRIPTS

getFileFromURL https://bitbucket.org/raptus-it-services/prtg-sshfs-mount-sensor/raw/master/sshfs-mount-check.sh $PRTG_SCRIPTS

getFileFromURL https://bitbucket.org/raptus-it-services/prtg-storage-health-sensors/raw/master/scriptsxml/smartmontools.sh $PRTG_SCRIPTSXML

getFileFromURL https://bitbucket.org/raptus-it-services/prtg-storage-health-sensors/raw/master/scripts/raid-check-mdraid.sh $PRTG_SCRIPTS

getFileFromURL https://bitbucket.org/raptus-it-services/prtg-storage-health-sensors/raw/master/scripts/raid-check-smartarray.sh $PRTG_SCRIPTS
