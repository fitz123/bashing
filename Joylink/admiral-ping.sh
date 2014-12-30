#!/bin/sh
while [ 1 -eq 1 ]; do
#eth=`cat /proc/net/bonding/bond0 | grep Active | sed 's/Currently Active Slave: //'`
#fails=`cat /proc/net/bonding/bond0 | grep $eth -A 4 | tail -n1 | grep -o "[0-9]"`
i=0
for host in "172.22.1.254" "172.22.0.72" "172.21.0.2"; do
  time=`date +%d-%H:%M:%S`
  loss=`ping -c100 -W 0.02 -i 0.01 -q $host 2>/dev/null | egrep -o "[0-9]\.[0-9]*%" | sed 's/\%//'`
  ping -c1 -W 0.05 -q $host > /dev/null 2>&1 || loss="100"
    if [ $loss != 0.0 ]; then
       i=`expr $i + 1`
       echo "$time      $host      $loss%" >> /root/ping.log
    fi
	echo "$time   $host   $loss%  $i"
done
  [ $i -eq 3 ] && logger "Packet losses"
done
exit 1
