#!/bin/bash

#Variables
defdir=/home/kalina
scriptdir=$defdir/scripts
devip=/home/kalina/alldev3

#Creating a records of the unused ports for each device
cat $devip | while read line 
        do

                #Getting credentials from line
                host=`echo $line | cut -d',' -f5`
                user="root"
                pass=`echo $line | cut -d',' -f3`

                #Execute the script to $output in raw format
                $scriptdir/vty_runcmd2.exp -m ssh -h $host -u $user -p $pass -e cisco -f $defdir/cmdfile6  > ./temp/$host
                res=`grep "bytes copied" ./temp/$host | wc -l`
                if [ $res -eq 2 ]; then
                        echo $host" OK"
                else
                        echo $host" failed"
                fi

                
        done


