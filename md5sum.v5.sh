#!/bin/bash
# 
# The script about md5sum multithread calculation
# Has been used for the to compare files before and after copy from the one server to the another
#
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
find "${root}" -type f ! -path "/media/samba/NAS/*" ! -path "/media/samba/nas/*" ! -path "/media/samba/printer/*" > $filelist.tmp
files=`wc -l $filelist.tmp | cut -d" " -f1`
echo -e "Find finished"'\t'$files" files found"'\t'`date`'\t'`date +%s` >> $log
echo -e "Find finished"'\t'$files" files found"'\t'`date`'\t'

echo -e "Shuffling the files starts"'\t'`date`'\t'`date +%s` >> $log
echo -e "Shuffling the files starts"'\t'`date`'\t'`date +%s`
shuf -o $filelist $filelist.tmp
echo -e "Shuffling the files finished"'\t'`date`'\t'`date +%s` >> $log
echo -e "Shuffling the files finished"'\t'`date`'\t'

if [ ! -d "$listdir" ]; then mkdir $listdir; fi
cd $listdir
maxjobs=$(nproc)
let splitby=$files/$maxjobs
#echo $files
#echo $splitby
split -l $splitby -a 10 $filelist
cd ../
find $listdir -type f > $lists

echo -e "Md5sum processing is started in ""$maxjobs"" parrallel threads"
echo -e "You can monitor how many files left by performing the followed command:"
echo -e 'echo $((`wc -l $listdir/x*.csv | tail -n1 | cut -d" " -f3` - $files))'
echo -e "Replace \"\$listdir\" by "$listdir" and \"\$files\" by "$files

date_s=`date +%s`

file_proc () {
    file=$1
    sum=`md5sum "${file}" | cut -d" " -f1`
    fname=//"${file#/media/}"
    sname="${file#/media/samba/*/}"
    echo -e $sum'\t'$sname'\t'$fname >> $list.csv
#    echo "File ""${file##*/}"" has been processed"
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