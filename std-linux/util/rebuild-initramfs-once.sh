#!/bin/bash
#
# Need to rebuild initram FS due to changes of sysctl
#

source /root/scripts/rsl/common.inc
checkLockFile

/root/scripts/rsl/std-linux/util/rebuild-initramfs.sh >> $LOGFILE 2>&1 &

# eof