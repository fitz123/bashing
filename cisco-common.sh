#!/bin/bash
#
# This is the common script for the cisco tcl
# You wanna to change tcl commands starting after "printf"
# You also wanna to change success criteria, the "comm" variable. If the "comm" performed successfully script thinks everything is ok
# 
# The current script is the example of "Add public auth key for all of the switches"
# The pubkey auth is added if the "key-hash" command is performed successfully
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

comm="key-hash"

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
                
                # Check if the main commands have been successfully executed
		#
		res=`egrep -A 2 "$comm" $defdir/temp-comm/$host | tail -n1 | grep "SUCCESS" | wc -l`
                if [ $res -eq 1 ]; then
                        echo $host" OK"
                else
                        echo $host" fail"
                fi
        done

#rm -rf $defdir/temp-comm
