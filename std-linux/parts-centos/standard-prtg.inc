echo "### Setting up PRTG tools"
yum -y install python-psutil >> $LOGFILE

mkdir -p /var/prtg/scripts
mkdir -p /var/prtg/scriptsxml

curl --silent https://bitbucket.org/raptus-it-services/prtg-process-sensor/raw/master/process-monitor.py -o /var/prtg/scriptsxml/process-monitor.py

curl --silent https://bitbucket.org/raptus-it-services/prtg-lemp-stack-sensor/raw/master/lemp-stack-check.sh -o /var/prtg/scriptsxml/lemp-stack-check.sh

curl --silent https://bitbucket.org/raptus-it-services/prtg-lemp-stack-sensor/raw/master/phpfpm-ping-check.sh -o /var/prtg/scripts/phpfpm-ping-check.sh

curl --silent https://bitbucket.org/raptus-it-services/prtg-sshfs-mount-sensor/raw/master/sshfs-mount-check.sh -o /var/prtg/scripts/sshfs-mount-check.sh

curl --silent https://bitbucket.org/raptus-it-services/prtg-storage-health-sensors/raw/master/scriptsxml/smartmontools.sh -o /var/prtg/scriptsxml/

curl --silent https://bitbucket.org/raptus-it-services/prtg-storage-health-sensors/raw/master/scripts/raid-check-mdraid.sh -o /var/prtg/scripts/raid-check-mdraid.sh

curl --silent https://bitbucket.org/raptus-it-services/prtg-storage-health-sensors/raw/master/scripts/raid-check-smartarray.sh -o /var/prtg/scripts/raid-check-smartarray.sh
