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
file prompt quiet
end
copy run tftp://192.168.99.70/
copy run flash:backup-config
conf t
no file prompt quiet
end
wr" > $defdir/cmdfile-cfg

#Creating a records of the unused ports for each device
cat $devip | while read line 
        do
                #Getting credentials from line
                host=`echo $line | cut -d',' -f5`
                user="user"
                pass=`echo $line | cut -d',' -f3`
                epass="epass"

                #Execute the script to $output in raw format
                $scriptdir/vty_runcmd2.exp -m ssh -h $host -u $user -p $pass -e $epass -f $defdir/cmdfile-cfg  > $defdir/temp-cfg/$host
                
                # Check if all the commands have been successfully performed
                res=`grep "bytes copied" $defdir/temp-cfg/$host | wc -l`
                if [ $res -eq 2 ]; then
                        echo $host" OK"
                else
                        echo $host" failed"
                fi
        done


