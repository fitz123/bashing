#!/bin/sh

GW=`netstat -rn | grep default | egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"`
lan_inf="em1"

ping -c 5 -i 0.1 -q $GW >/dev/null
  if [ $? != 0 ]; then
    logger "GW:$GW sucks"
    ping -c 5 -q ya.ru >/dev/null
      if [ $? != 0 ]; then
         /sbin/dhclient $lan_inf || /sbin/pfctl -o basic -f /tmp/rules.debug
        logger "GW:$GW Crash!"
      fi
  fi
exit 1