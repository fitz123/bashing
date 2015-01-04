#!/bin/bash

# Script periodically uploads to git a file

# Set variables
gdir="/opt/spy"
file="autobrightness-sample.jpg"
sdir="/tmp"
commit='date +%Y/%m/%d-%H:%M:%S'
sleep=$(cat ~/.config/wildguppy/config.json | cut -d\" -f4)
condition="wildguppy.py"

cd $gdir
git remote set-url origin https://fitz123@bitbucket.org/fitz123/spy.git
let stime=$sleep+3

while [ `ps -ef | grep "$condition" | wc -l` -gt 1 ]; do 
	git --work-tree=$sdir add $file && \
	git commit -m "`$commit`"
	ptime=`date +%M | sed 's/^.//'`
	[ $ptime -eq 0 ] && git push origin master && sleep 60
	sleep $stime
done
exit 0
