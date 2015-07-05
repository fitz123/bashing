#!/bin/bash
#
# Description: Sync dir across multiple servers
# Version: 0.8
# Contact me: spam.me.plz@outlook.com
#
# HOW TO, WARNINGS, REQUIREMENTS : 
# 
# 0. This script have to be executed from the Master server 
# 1. Sync software have to be installed and configured on the Master server manually 
#    before script started 
# 2. Sync directory ($target) on the Master server have to have "testfile" only before script started 
# 3. On the Master server need to update /etc/ssh/ssh_config > StrictHostKeyChecking no 
# 4. Although there is the user variable it can not be changed 
# 5. Master server's ssh public key have to be authorized across all the nodes before script started  
# 6. You need 4 files for deployment: CopyConsole, copy-start.sh, master.sh, node.db 
# 7. Here is no log file, but you can use "debug" mode. 
#    For that all "echo" which located in the first column have to be uncommented 
# 8. The script has been tested on CentOS 6 x86_64 minimal installation only
#
#
home=.
key="/home/fitz123/upwork/upwork-tests.pem"
target="/home/minecraft/multicraft"
user="root"
nodedb="$home/node.db"

[ -f $home/CopyConsole -a -f $home/copy-start.sh -a -f $home/node.db ] || { echo "Script files are missed. Abort" ; exit 1; }

for server in `cat $nodedb`
do
	ping -c2 $server > /dev/null || { echo "Server $server is unreachable. Skip"; continue; }
	ssh -q -i $key $user@$server -- [ -f $target/testfile ] && { echo "Server $server is ready."; continue; }
	echo Processing server: $server
	scp -i $key $home/copy-start.sh $user@$server:/root/ > /dev/null || { echo "Initial-start script copy failed for node $server. Skip node"; continue; }
	scp -i $key $home/CopyConsole $user@$server:/etc/init.d > /dev/null || { echo "Init-start script copy failed for node $server. Skip node"; continue; }
	ssh -q -i $key $user@$server -- "rpm -qa | grep wget > /dev/null || yum -y -q install wget > /dev/null"
	ssh -q -i $key $user@$server -- "rpm -qa | egrep "^at-.*x86_64" > /dev/null || { yum -y -q install at > /dev/null && service atd start > /dev/null ;}"
	ssh -q -i $key $user@$server -- "getent passwd minecraft > /dev/null 2&>1 || useradd minecraft"
	ssh -q -i $key $user@$server -- "[ -d $target ] || mkdir -p $target"
	ssh -q -i $key $user@$server -- "[ "$(stat -c "%a" $target)" == "755" ] || chmod 755 "$target""
	ssh -q -i $key $user@$server -- "[ "$(stat -c "%U" $target)" == "minecraft" ] || chown minecraft "$target""
	ssh -q -i $key $user@$server -- "[ "$(stat -c "%G" $target)" == "minecraft" ] || chgrp minecraft "$target""
echo "Starting sync software download..."
	ssh -q -i $key $user@$server -- wget -q -O /root/Copy.tgz "https://copy.com/install/linux/Copy.tgz" || { echo "Sync software wasn't downloaded for node $se. Skip node"; continue; }
echo "Sync software downloaded. Extracting..."
	ssh -q -i $key $user@$server -- tar zxvf Copy.tgz -C /root > /dev/null || { echo "Extraction failed for node $server. Skip node"; continue; }
echo "Software unpacked"
	ssh -q -i $key $user@$server -- /root/copy-start.sh
echo "Initial sync script started"
	ssh -q -i $key $user@$server -- chkconfig --add CopyConsole
echo "Sync script added to startup"
	sleep 10 && ssh -q -i $key $user@$server -- [ -f $target/testfile ] || { echo "Something failed. Sync doesn't start for node $server. Skip node"; continue; }
	echo "Sync for node $server established successfully. Next node"
done

exit 0
