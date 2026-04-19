#!/bin/bash

function tuneDevice
{
    device=$1

    # For bigger transfers
    ip link set $device txqueuelen 10000 > /dev/null 2>&1

    # Increase RX ring buffer
    ethtool -G $device rx 1024 > /dev/null 2>&1
}

###

# find all ethernet devices
for dev in "`ip -o link show | awk -F': ' '{print $2}' | grep -v lo`"
do
    tuneDevice $dev
done

# let’s increase the TCP congestion window from 1 to 10 segments
defrt=`ip route | grep "^default" | head -1`
ip route change $defrt initcwnd 10 > /dev/null 2>&1

# ensure rc.local does not fail
exit 0

# eof
