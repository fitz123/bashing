#!/bin/bash

#Variables
defdir=/etc/cisco_logging_of_free_ports
scriptdir=/usr/local/sbin
devip=/var/ftp/pub/cisco/$1
result="/var/ftp/pub/cisco/$1_SN.html"
resultweb="/usr/local/share/zabbix/cisco_$1-switches.html"
delim='</td><td>'
egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" /var/ftp/pub/cisco/$1 | sort | uniq > /tmp/$1
mv /tmp/$1 /var/ftp/pub/cisco/$1
i=0

#Create a file with remote tcl commands
printf "sh inventory" > $defdir/cmdfile

#file title
head="<html><table cols="5"><tr><td>Local Device name"$delim"IP address"$delim"Serial Number"$delim"Model"$delim"DNS Name</td></tr>"
echo $head > $result

#Creating a records of the unused ports for each device
cat $devip | while read line
  do
    output=/tmp/$line.tmp
    # Execute tcl commands. Credentials are inside the vty_runcmd.exp file
    $scriptdir/vty_runcmd.exp -h $line -f $defdir/cmdfile > $output
    #
    devname=`cat $output | egrep -o '^.*>|^.*#' | tail -n1 | sed s/.$//`
    # Grab the information
    NM=`grep "Connected to" $output | head -n1 | sed s/"Connected to "// | sed 's/ .*//g'`
    IP=`echo $line | grep -o '[0-9].*[0-9]'`
	    if [ ! -n "$devname" ]; then
        devname=`grep "Connected to" $output | head -n1 | egrep -o '\(.*\)' || echo "FAILED"`
	    fi
    cat $output | grep "System serial number"  | egrep -o '[[:upper:]][A-Z0-9]{10}' | while read SN
      do
        let "i++"
        ML=`cat $output | grep "Model number" | sed 's/.*Model number.*://g'| sed s/'\s'//g | sed -n "$i p"`
        echo "<tr><td>"$devname$delim$IP$delim$SN$delim$ML$delim$NM"</td></tr>" >> $result
			  #echo $devname$delim$IP$delim$SN$delim$ML$delim$NM
        echo $IP	$SN
      done
	  SN=`cat $output | grep "System serial number"  | egrep -o '[[:upper:]][A-Z0-9]{10}'`
      if [ ! -n "$SN" ]; then
        SN=`cat $output | grep "Processor board ID" | egrep -o '[[:upper:]][A-Z0-9]{10}' || echo "FAILED"`
        ML=`cat $output | grep "cisco " | cut -d " " -f 2` 
        echo "<tr><td>"$devname$delim$IP$delim$SN$delim$ML$delim$NM"</td></tr>" >> $result
        #echo $devname$delim$IP$delim$SN$delim$ML$delim$NM
        echo $IP        $SN
      fi
  done

rm $output
cat $result | uniq > /tmp/$1
mv /tmp/$1 $result
cp $result $resultweb

exit 1
