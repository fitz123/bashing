#!/bin/bash

#Variables
defdir=/home/kalina
scriptdir=$defdir/scripts
devip=$defdir/alldev3
ph=';' #place holder
result=$defdir/dlinks.txt

#Create a file with remote tcl commands
printf "show interfaces status\nshow mac address-table\n" > $defdir/cmdfile-dlink

#Check file title
echo "Switch name"$ph"IP address"$ph"Users"$ph"Dlink-connected port" > $result

#Check folder for temporary result save
[ -d "$defdir/temp-mac-tables/" ] || mkdir $defdir/temp-mac-tables

#Creating a records of the unused ports for each device
cat $devip | while read line
    do
        #Getting credentials from $line
        host=`echo $line | cut -d',' -f5`
        user=`echo $line | cut -d',' -f7`
        pass=`echo $line | cut -d',' -f3`
        epass=`echo $line | cut -d',' -f6`
        #Temp dir
        output=$defdir/temp-mac-tables/$host
        #Execute the script to $output in raw format
    	$scriptdir/vty_runcmd.exp -m ssh -h $host -u $user -p $pass -f $defdir/cmdfile-dlink > $output
        #
        #Clear output: removing "^M", "tabulators", "--More--" and replacing more that 1 space to 1 space
        sed -i 's/\x0D//g;s/\x08\{3\}//g;s/--More--//g;s/ \+/ /g' $output
        devname=$(cat $output | egrep ".*[>#]$" -m 1 | sed 's/[>#]//')
        #
        # Lets do the magic!
        # Firts of all we need to determine trunk ports to exclude them
        # 1. Show the file between 1st and 2nd tcl commands, include ports strings only
        # 2. Include "trunk" only, 1st word (port), joint strings (ports) and replace spaces to "|" - for further usage by grep
        trunks=$(sed -e '1,/show interfaces status/d;/mac address/,$d' $output | egrep "Gi[0-9]|Fa[0-9]|Te[0-9]|Po[0-9]" |\
        grep trunk | cut -d" " -f1 | xargs | sed 's/ /|/g')
        #
        # Here we show output beginning from the 2nd tcl command (show mac address-table)
        # 1. We have to exclude "$trunks", "CPU" and " 57 " vlan contained strings
        # 2. By awk and we print ports only. By "uniq -D" we print duplicates only, by "uniq -c" we count how many times it duplicates
        # 3. In the end we add Device name and its IP address at the begin of each line and write result to the $result
        # In total we have list on the ports that have more than 1 mac behind and how many
        sed -e '1,/show mac address-table/d' $output | egrep -i -v "$trunks|CPU| 57 " | egrep "Gi[0-9]|Fa[0-9]|Te[0-9]|Po[0-9]" |\
        awk '{print $4}' | uniq -D | uniq -c |\
        sed "s/^/$devname $host/" | sed "s/ \+/$ph/g" >> $result
        echo "Host $host processed"
    done
scp $result lugovoy@192.168.99.8:/media/samba/oit
