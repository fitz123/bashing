#!/bin/sh

#set variables
link0='https://dl.dropbox.com/s/xbq8d3ismvs1gqo/temp.txt?dl=1'
link1='https://dl.dropbox.com/s/9yy2d3g4j81m43c/paid.txt?dl=1'
link2='https://dl.dropbox.com/s/yk2ck3p8ql6vf1g/freemen.txt?dl=1'
link3='https://dl.dropbox.com/s/fd3bb8xexdkitdm/exp.txt?dl=1'
cd /home/kir/ftp
[ -f ./duplicate.txt ] && rm ./duplicate.txt
i=0

for alias in $@
do
        case $alias in
                temp )
                wget $link0 -O "$alias" >/dev/null 2>&1 ;;
                paid )
                wget $link1 -O "$alias" >/dev/null 2>&1 ;;
                freemen )
                wget $link2 -O "$alias" >/dev/null 2>&1 ;;
                exp )
                wget $link3 -O "$alias" >/dev/null 2>&1 ;;

	esac

#remove strings not started with IP
cat $alias | egrep "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" > $alias.tmp
#delete all not start with "1"
sed -i 's/[^1]*//' $alias.tmp
#delete all between IP and comment
sed -i 's/\([0-9.]*\)\(.*\)\(#.*\)/\1\3/' $alias.tmp
#add tab-symbol before comment
sed -i 's/#/	#/g' $alias.tmp

#clear alias - only IPs
egrep -o "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" $alias.tmp | sort > $alias && \
cp $alias{,.clr}

if [ $alias = temp ]; then
#delete duplicates
cat $alias | while read ip; do
	grep "$ip$" "paid.txt" "freemen.txt" >/dev/null && \
	sed -i "/$ip/d" $alias.tmp && \
	sed -i "/$ip/d" $alias.clr && \
	echo "$ip	duplicated" >> ./duplicate.txt
done
fi

if [ -s $alias.clr ]; then
diff $alias.txt $alias.clr 2>/dev/null
if [ $? -ne 0 ]; then
	i=$((i+1))
	mv $alias.tmp ./backup/$alias`date +-%y.%m.%d.%H:%M`.txt
	mv $alias.clr $alias.txt
	rm $alias
	scp /home/kir/ftp/$alias.txt sync@admiral:/var/db/aliastables/$alias.txt && \
	echo `date +%d.%H:%M`"	$alias	successfully changed and uploaded"
	echo `date +%d.%H:%M`"	$alias	successfully changed and uploaded" >> ./log.txt
else
	rm $alias{,.tmp,.clr}
	echo `date +%d.%H:%M`"	$alias no updates"
fi
else
	echo `date +%d.%H:%M`"	$alias incorrect"
	rm $alias{,.tmp,.clr}
fi

done

#if [ $i -ne 0 ]; then
#	ssh -l admin admiral -- /home/sync/sync.sh
#fi

exit 1