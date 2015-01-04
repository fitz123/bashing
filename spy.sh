#!/bin/bash
#
# Script periodically uploads to git a $file
# 
# For download all the file versions you need to execute:
# mkdir /tmp/dump && git log --oneline > /tmp/dump/log
# while read i; do git show `echo $i | cut -d" " -f1`:autobrightness-sample.jpg \
# > "/tmp/dump/`echo $i | cut -d" " -f2 | sed 's/\//-/g'`.jpg" ; done </tmp/dump/log 
#

# Set variables
gdir=~/spy/
file="autobrightness-sample.jpg"
sdir="/tmp"
commit='date +%Y/%m/%d-%H:%M:%S'
sleep=$(cat ~/.config/wildguppy/config.json | cut -d\" -f4)
condition="wildguppy.py"
repo="https://fitz123@bitbucket.org/fitz123/spy.git"
pushevery=600

# Check if work directory exist
[ -d $gdir ] || { mkdir -p $gdir && cd $gdir && git clone $repo; }
cd $gdir
git remote set-url origin $repo

# Script starts
let stime=$sleep+3
let time1=`date +%s`/$pushevery

# If a process $condition doesn't run - sleep for a 5 mins 
while true; do
	
	# While a process $condition up and running we add and commit our file 
	while [ `ps -ef | grep "$condition" | wc -l` -gt 1 ]; do 
		git --work-tree=$sdir add $file && \
		git commit -m "`$commit`"
		# Check the time, if more then $pushevery time left - do the push
		let time2=`date +%s`/$pushevery
		[ $time1 -ne $time2 ] && git push origin master && time1=$time2
		sleep $stime
	done

sleep 300
done

exit 0
