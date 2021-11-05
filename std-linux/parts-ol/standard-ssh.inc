echo "### Setting up ssh"

$STD_PATH/util/ssh-generate-key.sh root >> $LOGFILE

ln -sf /usr/share/crypto-policies/LEGACY/opensshserver.txt opensshserver.config
