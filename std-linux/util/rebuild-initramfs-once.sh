#!/bin/bash
#
# Need to rebuild initram FS due to changes of sysctl
#

source /root/scripts/rsl/common.inc
checkLockFile

$STD_PATH/util/rebuild-initramfs.sh >> $LOGFILE 2>&1 &

# eof