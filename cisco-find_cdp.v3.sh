#!/bin/bash

#Variables
ph=',' #place holder
defdir=/home/kalina
result=$defdir/nei.csv
scriptdir=/home/kalina
devip=/home/kalina/alldev3
ph=',' #place holder
tmp_result=`mktemp`
tftp_serv="192.168.100.33"


#Creating a records of the unused ports for each device
cat $devip | while read line; do

     #Getting credentials from line
     host=`echo $line | cut -d',' -f5 | sed 's/\x0D//g;s/\x08\{3\}//g;s/--More--//g;s/  \+/;/g'`
     user="root"
     pass=`echo $line | cut -d',' -f3`

     output=$defdir/temp-cdp/$host
     output2=$defdir/temp-cdp/$host-2

     #Execute the script to $output in raw format
     $scriptdir/vty_runcmd2.exp -m ssh -h $host -u $user -p $pass -f $defdir/cmdfile5 > $output

     #Review only strings contained interface type and 1 string above
     grep -ve "--" $output | grep -v "NAME:" | grep -v "Device ID" | egrep -B 1 "Fas|Gig|Ten" > $output2

     #Clear output: removing "^M", "tabulators", "--More--" and replacing more then 1 space to ;
     sed -i 's/\x0D//g;s/\x08\{3\}//g;s/--More--//g;s/  \+/;/g' $output2

     #Join successive rows in pairs
     sed -i 'N;s/\n//' $output2

     #Getting the name of the switch, a model and a serial number
     name=`cat $output | egrep ".*[>#]$" -m 1 | sed 's/[>#]//' | sed 's/\x0D//g;s/\x08\{3\}//g;s/--More--//g'`
     model=`grep "NAME: \"1\", DESCR:" $output | cut -d":" -f3 | tr -d ' ','"' | sed 's/\x0D//g;s/\x08\{3\}//g;s/--More--//g'`
     sn=`egrep -A 1 "NAME: \"1"\" $output | tail -n1 | cut -d: -f4 | tr -d ' ' | sed 's/\x0D//g;s/\x08\{3\}//g;s/--More--//g'`

     #Getting the cells
     switchs=`cat $output2 | cut -d";" -f1`
     loc_ints=`cat $output2 | cut -d";" -f2`
     sw_mods=`cat $output2 | cut -d";" -f5 | cut -d" " -f1`
     sw_ints=`cat $output2 | cut -d";" -f5 | cut -d" " -f2,3`

     howmany() { echo $#; }
     sw_count=`howmany $switchs`

         COUNTER=0
         let i1=1
         let i2=2
         let s1=0
         while [  $COUNTER -lt $sw_count ]; do
             let s1=s1+1
             loc_int=`echo -e $loc_ints | cut -d" " -f$i1,$i2`
             switch=`echo -e $switchs | cut -d" " -f$s1`
             sw_mod=`echo $sw_mods | cut -d" " -f$s1`
             sw_int=`echo $sw_ints | cut -d" " -f$i1,$i2`
             echo $host$ph$name$ph$model$ph$sn$ph$loc_int$ph$switch$ph$sw_mod$ph$sw_int >> $result

#echo -e "host="$host
#echo -e "switch_count"=$sw_count
#echo -e "name="$name
#echo -e "model="$model
#echo -e "switch="$switch
#echo -e "loc_int="$loc_int
#echo -e "sw_mod="$sw_mod
#echo -e "sw_int="$sw_int
#echo -e "sn="$sn

             let i1=i1+2
             let i2=i2+2
             let COUNTER=COUNTER+1
         done

     #Checking if the Name of switch and output exist
    if [[ -n $name ]] && [[ -e $output2 ]]; then
        echo $name" "$IP" done"
    else
        echo $host" "$IP" error"
    fi

    #rm $output{,2}
done

exit 0
