#!/bin/bash
#
# The script is about 2 different folders synchronization
# The script has been used for synchronize SMB and DFS directories by templates
# You want to set variables for usernames and passwords (public key is used for ssh)
#
# Script executes with a parameter. For example:
#
# ./sync.sh ubs
# Will sync /mnt/dfs/ubs --> /mnt/sshfs/ubs (preserve all, delete extraneous files from destination dirs)
# by mounting //dfsserver1/PrintShare/UBS to $dfsmountpoint/ubs
# and \\samba\print\UBS to $dfsmountpoint/ubs
#
#
dfsuser="s2/dfs-username"
dfspassword="dfs-password"
sshuser="ssh-username"
sshhost="ssh-server1"
dfsmountpoint="/mnt/dfs"
sshmountpoint="/mnt/sshfs"
log="/log/ssh2dfs/$1.sync.log"
err="/log/ssh2dfs/$1.err.log"

sshmount () {
        mount | grep -c  $sshmountpoint/$1 >/dev/null 2>&1

        if [ $? -ne 0 ]; then
                echo $sshmountpoint/$1 "does not mounted"
                echo "SSHFS mount in progress"
                [ -d $sshmountpoint/$1 ] || mkdir -p $sshmountpoint/$1
                echo sshfs $sshuser@$sshhost:$sshpath $sshmountpoint/$1 -o reconnect,allow_root,hard_remove
                sshfs $sshuser@$sshhost:$sshpath $sshmountpoint/$1 -o reconnect,allow_root,hard_remove >/dev/null 2>&1
                [ $? -ne 0 ] && { logger 'sync: FAILED! SSH dir cannot be mounted. Terminated' ; echo 'sync: FAILED! SSH dir cannot be mounted. Terminated' ; exit 1; }
                return 0
        fi
}

dfsmount() {
        echo $dfspath1
        echo $dfspath2
        mount | grep -c  $dfsmountpoint/$1 >/dev/null 2>&1

        if [ $? -ne 0 ]; then
                echo $dfsmountpoint/$1 "does not mounted"
                echo "DFS mount in progress"
                [ -d $dfsmountpoint/$1 ] || mkdir -p $dfsmountpoint/$1
                echo mount -t cifs $dfspath1 $dfsmountpoint/$1 -o user=$dfsuser,password=$dfspassword
                mount -t cifs $dfspath1 $dfsmountpoint/$1 -o user=$dfsuser,password=$dfspassword >/dev/null 2>&1
                [ $? -ne 0 ] && { logger 'sync: FAILED! DFS dir cannot be mounted. Terminated' ; echo 'sync: FAILED! DFS dir cannot be mounted. Terminated' ; exit 1; }
                if ! [ -z "dfspath2" ]; then
                        mount | grep -c  $dfsmountpoint/$1 >/dev/null 2>&1
                        if [ $? -ne 0 ]; then
                                echo $dfsmountpoint/$1 "does not mounted"
                                echo "DFS mount in progress"
                                [ -d $dfsmountpoint/$1 ] || mkdir -p $dfsmountpoint/$1
                                echo mount -t cifs $dfspath2 $dfsmountpoint/$1 -o user=$dfsuser,password=$dfspassword
                                mount -t cifs $dfspath2 $dfsmountpoint/$1 -o user=$dfsuser,password=$dfspassword >/dev/null 2>&1
                                [ $? -ne 0 ] && { logger 'sync: FAILED! DFS dir cannot be mounted. Terminated' ; echo 'sync: FAILED! DFS dir cannot be mounted. Terminated' ; exit 1; }
                        fi
                fi
                return 0
        fi
}

sync() {
        dir=`basename "${sync_dst}"`
        echo "Sync "$sync_src" --> "$sync_dst" starting"
        stime=`date +%s`
        rsync --progress --delete -utr -O "${sync_src}" "${sync_dst}" >$log 2>>$err
        if [ $? -eq 0 ]; then
                chd=`grep -c xfer $log`
                del=`grep -c deleting $log`
                etime=`date +%s`
                let time=$etime-$stime
                logger "sync: OK! Folder "$dir" is synchonized in "$time" sec." $chd" files has been changed and "$del" files deleted."
                return 0
        else
                logger "sync: FAILED! Sync of the "$dir" folder is failed at "`date`"."
                echo "sync: FAILED! Sync of the "$dir" folder is failed at "`date`"."
                echo "sync: FAILED! Sync of the "$dir" folder is failed at "`date`"." >> $err
                return 1
        fi
}

case $1 in
ubs)
#
# файлы для маркираторов - загрузка с DFS на их старое место на самбе
# //dfsserver1/PrintShare/UBS --> \\samba\print\UBS
#
dfspath1="//dfsserver1/PrintShare/UBS"
sshpath="/media/samba/printer/UBS"
syncdir1="$1"
sync_src="$dfsmountpoint/$1/"
sync_dst="$sshmountpoint/$1/"

dfsmount $1 && echo "DFS folder is OK"
sshmount $1 && echo "SSH folder is OK"

sync "${syncdir1}" && echo "Sync ""${syncdir1##*/}"" is completed"
;;

Domino)
#
# Почтовые файлы Domino
# \\samba\oit\DOMINO --> \\dfsserver1\DOMINO_migration\nsf
#
dfspath1="//dfsserver1/DOMINO_migration/nsf"
sshpath="/media/samba/oit/DOMINO"
syncdir1="$1"
sync_src="$sshmountpoint/$1/"
sync_dst="$dfsmountpoint/$1/"

dfsmount $1 && echo "DFS folder is OK"
sshmount $1 && echo "SSH folder is OK"

sync "${syncdir1}" && echo "Sync ""${syncdir1##*/}"" is completed"
;;

*)

echo "Wrong or missed parameter."
;;

esac
