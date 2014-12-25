#!/bin/bash

#Variables
defdir=/etc/cisco_logging_of_free_ports
scriptdir=/usr/local/sbin
devip=/var/ftp/pub/cisco/$1
result="/var/ftp/pub/cisco/$1-links(`date +"%m"`).html"
resultweb="/usr/local/share/zabbix/cisco_$1-links.html"
delim='</td><td>'
egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" /var/ftp/pub/cisco/$1 | sort | uniq > /tmp/$1
mv /tmp/$1 /var/ftp/pub/cisco/$1
#
#
#Create a file with remote tcl commands
printf "sh int\nsh ver\n" > $defdir/cmdfile
#
#file title
head="<html><table cols="7"><tr><td>Local Device name"$delim"IP address"$delim"Check date"$delim"All/Down"$delim"Port Name"$delim"Port Status"$delim"Last used</td></tr>"
echo $head > $result

#Creating a records of the unused ports for each device
cat $devip | while read line
	do
		output=$line
		# Execute tcl commands. Credentials are inside the vty_runcmd.exp file
		$scriptdir/vty_runcmd.exp -h $line -f $defdir/cmdfile > $output
		#
		devname=`cat $output | egrep -o '^.*>|^.*#' | tail -n1 | sed s/.$//`
		# Grab the information
		# 
		IP=`echo $line | grep -o '[0-9].*[0-9]'`
		allports=`cat $output | grep tEthernet | wc -l`
		free=`cat $output | grep "is down, line protocol is down" | grep -v "sh int" | wc -l`

		egrep "GigabitEthernet[0-9]|FastEthernet[0-9]" $output | sed 's/\x08\{3\}//g' | sed 's/--More--//g' | while read str
	     do
		int=`echo $str | cut -d " " -f1`
		status=`echo $str | grep -o "(.*)" | sed 's/[()]//g'`
		  if [ ! -n "$status" ]; then
		    status="unknown"
		  fi
		used=`cat $output | grep "$int " -A20 | grep hang | sed 's/\x08\{3\}//g' | sed 's/--More--//g' | cut -d "," -f1,2`
		echo "<tr><td>"$devname$delim$IP$delim`date +"%d.%m.%y"`$delim$allports/$free$delim$int$delim$status$delim$used"</td></tr>" >> $result
	     done
		rm $output
	done

rm $output
cat $result | uniq > /tmp/$1
mv /tmp/$1 $result
cp $result $resultweb

exit 1
