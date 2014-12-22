#!/bin/bash

#Variables
defdir=/home/kalina
scriptdir=$defdir
devip=$defdir/alldev
ph=',' #place holder
result=$defdir/dlinks.txt

#Create a file with remote tcl commands
printf "show interfaces status\nshow mac address-table\n" > $defdir/cmdfile

#Check file title
#echo "Switch name"$ph"Module Name"$ph"Module Describe"$ph"Serial Number" > $result

#Creating a records of the unused ports for each device
cat $devip | while read line
    do
     host=`echo $line | cut -d',' -f5 | sed 's/\x0D//g;s/\x08\{3\}//g;s/--More--//g;s/  \+/;/g'`
        if [ -d "$DIRECTORY" ]; then
            output=$defdir/temp-mac-tables/host
        else
            mkdir $defdir/temp-mac-tables
            output=$defdir/temp-mac-tables/host
        fi
     #Getting credentials from $line
     user="root"
     pass=`echo $line | cut -d',' -f3`

     #Execute the script to $output in raw format
     $scriptdir/vty_runcmd.exp -m ssh -h $host -u $user -p $pass -f $defdir/cmdfile > $output

                #Clear output: removing "^M", "tabulators", "--More--" and replacing more that 1 space to 1 space
                sed -i 's/\x0D//g;s/\x08\{3\}//g;s/--More--//g;s/ \+/ /g' $output
                devname=`cat $output | egrep ".*[>#]$" -m 1 | sed 's/[>#]//'`
                cat $output | grep NAME: | while read name
                        do
                                #Get a module name and describe of it
                                module=`echo $name | cut -d, -f1 | sed s/NAME://g || unknown`
                                desc=`echo $name | cut -d, -f2 | sed s/DESCR://g | sed 's/.$//' || unknown`
                                #Grab the Cisco SNs
                                SN=`cat $output | grep -A 1 -e "$name" | grep -o "SN:.*" | sed s/SN://g || unknown`
                                echo $devname$ph$module$ph$desc$ph$SN >> $result
                        done
#                rm $output
    done

