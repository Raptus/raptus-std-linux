echo "### Setting up ssh"

$SCRIPTPATH/util/ssh-generate-key.sh root >> $LOGFILE
$SCRIPTPATH/util/ssh-generate-key.sh radmin >> $LOGFILE
