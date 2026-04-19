echo "### Setting up ssh"

$STD_PATH/util/ssh-generate-key.sh root >> $LOGFILE

# To enable legacy SSH algorithms if needed:
# update-crypto-policies --set DEFAULT:SSH-LEGACY
