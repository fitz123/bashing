#!/bin/bash
# 
# The script about md5sum multithread calculation
# Has been used for the fileshare to compare files before and after copy
#
result="/home/lugovoy/md5sum.v5.csv"
log="/home/lugovoy/md5sum.v5.date"
filelist="/home/lugovoy/filelist.v5"
listdir="/home/lugovoy/filelists/"
lists="/home/lugovoy/lists"
#root="$1"
root="/media/samba/oit/DOMINO/"

echo -e "Previous result deleting is started"'\t'`date`'\t'`date +%s` >> $log
echo -e "Previous result deleting is started"'\t'`date`'\t'
rm -f $log
rm -f $result
rm -f $lists

find $listdir -type f -exec /bin/rm {} \;
echo -e "Previous result deleting is finished"'\t'`date`'\t'`date +%s` >> $log
echo -e "Previous result deleting is finished"'\t'`date`'\t'

echo -e "Find starts"'\t'`date`'\t'`date +%s` >> $log
echo -e "Find starts"'\t'`date`'\t'`date +%s`
find "${root}" -type f ! -path "/media/samba/NAS/*" ! -path "/media/samba/nas/*" ! -path "/media/samba/printer/*" > $filelist
files=`wc -l $filelist | cut -d" " -f1`
echo -e "Find finished"'\t'$files" files found"'\t'`date`'\t'`date +%s` >> $log
echo -e "Find finished"'\t'$files" files found"'\t'`date`'\t'

if [ ! -d "$listdir" ]; then mkdir $listdir; fi
cd $listdir
let maxjobs=`nproc`*3/2
let splitby=$files/$maxjobs
#echo $files
#echo $splitby
split -l $splitby -a 10 $filelist
cd ../
find $listdir -type f > $lists

date_s=`date +%s`

file_proc () {
    file=$1
    sum=`md5sum "${file}" | cut -d" " -f1`
    fname=//"${file#/media/}"
    sname="${file#/media/samba/*/}"
    echo -e $sum'\t'$sname'\t'$fname >> $list.csv
    echo "File ""${file##*/}"" has been processed"
#    echo -e $sum'\t'$sname'\t'$fname
}

#parallelize_f () {
#            jobcnt=(`jobs -p`)
#            if [ ${#jobcnt[@]} -lt $maxjobs ] ; then
#               echo ${#jobcnt[@]}
#                file_proc "$1" &
#                shift
#            fi
#wait
#}

while read list; do
        while read file; do file_proc "$file"; done < $list &
done < $lists

wait

cat $listdir/x*.csv >> $result
date_f=`date +%s`
let date_=($date_f-$date_s)

files=`wc -l $result | cut -d" " -f1`

echo -e "Proccess finished"'\t'$files" in "$date_" seconds"'\t'`date`'\t'`date +%s` >> $log
echo -e "Proccess finished"'\t'$files" in "$date_" seconds"'\t'`date`'\t'`date +%s`