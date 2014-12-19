#!/bin/bash

dir=/test-vol/testdir
err_r=0
err_w=0

while true; do
  i=0
  while [ $i -lt 1000000 ]; do
  	file=`cat /dev/urandom | tr -cd 'a-f0-9' | head -c 16`
    echo `cat /dev/urandom | head -c 512` > $dir/$file || { let "err_w++" ; echo `date +%T:%N`"       write error $err_w!" >> /root/disk-error.log && false || echo `date +%T:%N`"     write error $err_w!"; }
    cat $dir/$file > /dev/null || { let "err_r++" ; echo `date +%T:%N`"       read error $err_r!" >> /root/disk-error.log && false || echo `date +%T:%N`"      read error $err_r!"; }
    let "i++" 
  done
  rm -rf $dir && mkdir $dir
done
