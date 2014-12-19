#!/bin/sh

#set variables
dir='/var/db/aliastables'
link0='https://dl.dropbox.com/s/xbq8d3ismvs1gqo/temp.txt?dl=1'
link1='https://dl.dropbox.com/s/fd3bb8xexdkitdm/exp.txt?dl=1'
link2='https://dl.dropbox.com/s/9yy2d3g4j81m43c/paid.txt?dl=1'
link3='https://dl.dropbox.com/s/yk2ck3p8ql6vf1g/freemen.txt?dl=1'
i=0

cd $dir

for alias in $@
do
	case $alias in
		temp.txt )
		fetch -o $alias".tmp" $link0 >/dev/null 2>&1 && /root/proc_temp.sh 'temp.txt.tmp' ;;
		paid.txt )
		fetch -o $alias".tmp" $link2 >/dev/null 2>&1 ;;
		freemen.txt )
		fetch -o $alias".tmp" $link3 >/dev/null 2>&1 ;;
	esac
		if [ ! -f $dir/$alias ]; then
       		logger "Alias $alias had been deleted!!!"
			cp $alias".tmp" $dir/$alias
		fi
		#Get hashes of files
		if [ -f $dir/$alias".tmp" ]; then
			egrep -o "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" $alias".tmp" > $alias".tmp2"
        	hash0=$(md5 $alias".tmp2" | cut -d " " -f 4)
        	hash1=$(md5 $alias | cut -d " " -f 4)
       			#Compare and replace if files' hashes are different
       			if [ $hash0 != $hash1 ]; then
       				bak="$alias-`date +%d:%H`"
       				mv $alias $bak
       				cp $alias".tmp2" $alias
					i=$((i+1))
					echo "File $alias Successfully updated!"
					logger "File $alias Successfully updated!"
					#show true temp
					ftp -n <<EOF
					open 208.115.198.69
					user kir kir
					put $dir/$alias $alias
					put $dir/$bak $bak
					quit
EOF
					#fi
				else
					echo "With the file $alias no updates"
					#logger "With the file "$alias" no updates"
				fi
			rm $dir/$alias.* >/dev/null 2>&1
            rm $dir/$alias-* >/dev/null 2>&1
		fi
	done
if [ $i -ne 0 ]; then
	#APPLYING PFCT
	/sbin/pfctl -o basic -f /tmp/rules.debug
	logger "Alias: $alias successfully updated ($i). PF has been applied!"
fi

exit 1