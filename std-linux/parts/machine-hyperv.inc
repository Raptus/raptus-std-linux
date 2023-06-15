sed -i -r "s/(^GRUB_CMDLINE_LINUX=.*quiet)\"/\1 video=hyperv_fb:1024x768\"/g" /etc/default/grub
grub2-mkconfig >> $LOGFILE 2>&1
