#!/bin/bash

#Variables
defdir=/home/kalina
scriptdir=$defdir
devip=$defdir/alldev3
ph=',' #place holder
result=$defdir/cisco_SN.txt

#Create a file with remote tcl commands
printf "sh inventory" > $defdir/cmdfile-inv

#Check file title
echo "Switch name"$ph"Module Name"$ph"Module Describe"$ph"Serial Number" > $result

#Check folder for temporary result save
[ -d "$defdir/output-inv" ] || mkdir $defdir/output-inv

#Creating a records of the unused ports for each device
cat $devip | while read line
    do
        output=$defdir/output-inv
        #Getting credentials from line
        host=`echo $line | cut -d',' -f5`
        user=`echo $line | cut -d',' -f7`
        pass=`echo $line | cut -d',' -f3`
        epass=`echo $line | cut -d',' -f6`
        #Execute the script to $output in raw format
        $scriptdir/vty_runcmd2.exp -m ssh -h $host -u $user -p $pass -f $defdir/cmdfile-mod > $output
        #
        #Clear output: removing "^M", "tabulators", "--More--" and replacing more that 1 space to 1 space
        sed -i 's/\x0D//g;s/\x08\{3\}//g;s/--More--//g;s/ \+/ /g' $output
        devname=`cat $output | egrep ".*[>#]$" -m 1 | sed 's/[>#]//'`
        #
        cat $output | grep NAME: | while read name
        do
            #Get a module name and its description
            module=`echo $name | cut -d, -f1 | sed s/NAME://g || unknown`
            desc=`echo $name | cut -d, -f2 | sed s/DESCR://g | sed 's/.$//' || unknown`
            #Grab the module SN
            SN=`cat $output | grep -A 1 -e "$name" | grep -o "SN:.*" | sed s/SN://g || unknown`
            #Save result
            echo $devname$ph$module$ph$desc$ph$SN >> $result
        done
        #rm $output
    done