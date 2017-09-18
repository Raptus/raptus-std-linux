echo "### Setting up ssh"

$SCRIPTPATH/std-linux/util/ssh-generate-key.sh root >> $LOGFILE
$SCRIPTPATH/std-linux/util/ssh-generate-key.sh radmin >> $LOGFILE
