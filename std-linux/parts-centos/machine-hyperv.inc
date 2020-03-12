sed -i -r "s/(^GRUB_CMDLINE_LINUX=.*quiet)\"/\1 video=hyperv_fb:1024x768\"/g" /etc/default/grub
grub2-mkconfig >> $LOGFILE 2>&1

# Change to NOOP I/O scheduler
# See here: https://technet.microsoft.com/en-us/library/dn720239.aspx
# And here: https://www.certdepot.net/rhel7-configure-io-schedulers/
grubby --update-kernel=ALL --args="elevator=noop"
