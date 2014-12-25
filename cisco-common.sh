#!/bin/bash
#
# The script about saving running-config to the flash: memory and
# copying the config to the tfp server.
# All the cisco commands placed, as usually, inside the cmdfile
#
#Variables
defdir=/home/kalina
scriptdir=$defdir/scripts
devip=$defdir/alldev

#Create a file with remote tcl commands
printf "conf t
ip ssh pubkey-chain
username root
key-hash ssh-rsa 3AD13E192686B8AFD0A9F2F55451512A" > $defdir/cmdfile-comm

[ -d "$defdir/temp-comm/" ] || mkdir $defdir/temp-comm

#Creating a records of the unused ports for each device
cat $devip | while read line 
        do
                #Getting credentials from line
                host=`echo $line | cut -d',' -f5`
                user=`echo $line | cut -d',' -f7`
                pass=`echo $line | cut -d',' -f3`
                epass=`echo $line | cut -d',' -f6`

#echo $host $user $pass $epass

                #Execute the script to $output in raw format
                $scriptdir/vty_runcmd.exp -m ssh -h $host -u $user -p $pass -e $epass -f $defdir/cmdfile-comm  > $defdir/temp-comm/$host
                
                # Check if all the commands have been successfully performed
                #error="Invalid input detected"
		success="SUCCESS"
		res=`egrep -A 2 "key-hash" $defdir/temp-comm/$host | tail -n1 | grep "SUCCESS" | wc -l`
                if [ $res -eq 1 ]; then
                        echo $host" OK"
                else
                        echo $host" fail"
                fi
        done

#rm -rf $defdir/temp-comm
