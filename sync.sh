#!/bin/bash

dfsuser="s2/hw.refresh"
dfspassword="Unilever01"
sshuser="kubckyi"
sshhost="156.5.128.68"
dfsmountpoint="/mnt/dfs"
sshmountpoint="/mnt/sshfs"
log="/root/ssh2dfs/$1.sync.log"
err="/root/ssh2dfs/$1.err.log"

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
        rsync --progress -utr -O "${sync_src}" "${sync_dst}" >$log 2>>$err
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
# //156.5.128.185/PrintShare/UBS --> \\samba\print\UBS
#
dfspath1="//156.5.128.185/PrintShare/UBS"
sshpath="/media/samba/printer/UBS"
syncdir1="$1"
sync_src="$dfsmountpoint/$1/"
sync_dst="$sshmountpoint/$1/"

dfsmount $1 && echo "DFS folder is OK"
sshmount $1 && echo "SSH folder is OK"

sync "${syncdir1}" && echo "Sync ""${syncdir1##*/}"" is completed"
;;

job)
#
# файлы для маркираторов - загрузка с DFS на их старое место на самбе
# //156.5.128.185/PrintShare/Job --> \\samba\print\Job
#
dfspath1="//156.5.128.185/PrintShare/Job"
sshpath="/media/samba/printer/Job"
syncdir1="$1"
sync_src="$dfsmountpoint/$1/"
sync_dst="$sshmountpoint/$1/"

dfsmount $1 && echo "DFS folder is OK"
sshmount $1 && echo "SSH folder is OK"

sync "${syncdir1}" && echo "Sync ""${syncdir1##*/}"" is completed"
;;

certificates)
#
# загрузка сертификатов с DFS на их старое место на самбе, что бы с самбы сертификаты грузились дальше на веб-сервер
# \\s2\dfs\ES-GROUPS\cor\KLN\SC_QA\DSMK --> \\samba\ДСМК
#
dfspath1="//klnsapp20001.s2.ms.unilever.com/DSMK/20-ouk"
sshpath="/media/samba/dsmk/20-ОУК"
syncdir1="$1/Сертификация/Сертификаты"
syncdir2="$1/Сертификация/Требования по поиску документов"
syncdir3="$1/НТД/Перечни сертификатов"
sync_src="$dfsmountpoint/$1/"
sync_dst="$sshmountpoint/$1/"

dfsmount $1 && echo "DFS folder is OK"
sshmount $1 && echo "SSH folder is OK"

sync "${syncdir1}" && echo "Sync ""${syncdir1##*/}"" is completed"
sync "${syncdir2}" && echo "Sync ""${syncdir2##*/}"" is completed"
sync "${syncdir3}" && echo "Sync ""${syncdir3##*/}"" is completed"
;;

logist)
#
# выгрузка отчётов по стокам из САПа с самбы на их новое  место для логисто
# \\samba\logistics\Stock  --> \\s2\dfs\ES-GROUPS\cor\KLN\_PublicTemp\SC_Logistic\logistics\Stock
#
dfspath1="//klnsapp20001.s2.ms.unilever.com/_PublicTemp/SC_Logistic/logistics/Stock"
sshpath="/media/samba/logistics/Stock"
syncdir1="$1"
sync_src="$sshmountpoint/$1/"
sync_dst="$dfsmountpoint/$1/"

dfsmount $1 && echo "DFS folder is OK"
sshmount $1 && echo "SSH folder is OK"

sync "${syncdir1}" && echo "Sync ""${syncdir1##*/}"" is completed"
;;

test)
#
# тестовая директория
# \\klnsapp20001.s2.ms.unilever.com\_PublicTemp\123 and \\klnsapp20001.s2.ms.unilever.com\_PublicTemp\321
#
dfspath1="//klnsapp20001.s2.ms.unilever.com/_PublicTemp"
syncdir1="$1"
sync_src="$dfsmountpoint/$1/123/"
sync_dst="$dfsmountpoint/$1/321/"

dfsmount $1 && echo "DFS folder is OK"

sync "${syncdir1}" && echo "Sync ""${syncdir1##*/}"" is completed"
;;

base)
#
# скрипт из охраны по выгрузке данных по Табелю с самбы на DFS
# \\samba\tabel\Base\Base_T.mdb --> \\s2\dfs\ES-GROUPS\cor\KLN\_PublicTemp\APPS\tabel\Base\Base_T.mdb
#
dfspath1="//klnsapp20001.s2.ms.unilever.com/_PublicTemp/APPS/tabel/Base"
sshpath="/media/samba/tabel/Base"
syncdir1="$1"
sync_src="$sshmountpoint/$1/Base_T.mdb"
sync_dst="$dfsmountpoint/$1/Base_T.mdb"

dfsmount $1 && echo "DFS folder is OK"
sshmount $1 && echo "SSH folder is OK"

sync "${syncdir1}" && echo "Sync ""${syncdir1##*/}"" is completed"
;;

Process)
#
# Логи реакторов Siemens, тех. отдел Natalia.Musalnikova@unilever.com (1300), Natalia.Musalnikova@unilever.com (1301)
# \\samba\Process --> \\s2\dfs\ES-GROUPS\cor\KLN\SC_Common\Process
#
dfspath1="//klnsapp20001.s2.ms.unilever.com/SC_Common/Process"
sshpath="/media/samba/process"
syncdir1="$1"
sync_src="$sshmountpoint/$1/"
sync_dst="$dfsmountpoint/$1/"

dfsmount $1 && echo "DFS folder is OK"
sshmount $1 && echo "SSH folder is OK"

sync "${syncdir1}" && echo "Sync ""${syncdir1##*/}"" is completed"
;;

Levashov)
#
# сетевые доки Левашова
# \\samba\Process --> \\s2\dfs\ES-GROUPS\cor\KLN\SC_Common\Process
#
dfspath1="//klnsapp20001.s2.ms.unilever.com/_PublicTemp/Levashov"
sshpath="/media/samba/oit/Levashov"
syncdir1="$1"
sync_src="$sshmountpoint/$1/"
sync_dst="$dfsmountpoint/$1/"

dfsmount $1 && echo "DFS folder is OK"
sshmount $1 && echo "SSH folder is OK"

sync "${syncdir1}" && echo "Sync ""${syncdir1##*/}"" is completed"
;;

Domino)
#
# Почтовые файлы Domino
# \\samba\oit\DOMINO --> \\klnsarcsr01\DOMINO_migration\nsf
#
dfspath1="//156.5.128.185/DOMINO_migration/nsf"
sshpath="/media/samba/oit/DOMINO"
syncdir1="$1"
sync_src="$sshmountpoint/$1/"
sync_dst="$dfsmountpoint/$1/"

dfsmount $1 && echo "DFS folder is OK"
sshmount $1 && echo "SSH folder is OK"

sync "${syncdir1}" && echo "Sync ""${syncdir1##*/}"" is completed"
;;

Print)
#
# Временная синхронизация до переконфигурирования Шар
# \\klnsapp20001.s2.ms.unilever.com\_PublicTemp\123 and \\klnsapp20001.s2.ms.unilever.com\_PublicTemp\321
#
dfspath1="//klnsapp20001.s2.ms.unilever.com/_PublicTemp"
dfspath2="//156.5.128.185/PrintShare/temp"
syncdir1="$1"
sync_src="$dfsmountpoint/123/"
sync_dst="$dfsmountpoint/temp/"

dfsmount 123 && echo "DFS1 folder is OK"
dfsmount temp && echo "DFS2 folder is OK"

sync "${syncdir1}" && echo "Sync ""${syncdir1##*/}"" is completed"
;;

*)

echo "Wrong or missed parameter."
;;

esac
