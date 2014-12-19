#!/bin/bash

set -e
set -o pipefail

fd="/Orafra/SSDR/backupset/`date +%Y_%m_%d`"
bckp_sh='/Oracle/admin/scripts/backup/SSDR/arc_backup_SSDR.sh'
fail_msg='=============== ERROR MESSAGE STACK FOLLOWS ==============='
bckp_log='/Oracle/admin/scripts/backup/SSDR/arc_backup_SSDR.log'
rperm='-rwxr-xr-- oracle oinstall'
alert="/usr/sbin/zabbix_sender -c /etc/zabbix/zabbix_agentd.conf -k chk_bckp.util -o"

[ -e $bckp_sh ] || { $alert "ERROR1" ; exit 1; }
cperm=`ls -l $bckp_sh | cut -d " " -f1,3,4` && \
[[ $cperm == $rperm ]] || { $alert "ERROR2" ; exit 1; }
[ -e $bckp_log ] || { $alert "ERROR3" ; exit 1; }
[ -d $fd ] || { $alert "FAILED1" ; exit 2; }

grep "$fail_msg" "$bckp_log" && { $alert "FAILED2" ; exit 2; } 

chk="find $fd -type f -cmin -540 ! -size 0"
if [ `$chk | wc -l` -ne 0 ]; then
  $alert "OK"
  else
    { $alert ; exit 2; }
fi

exit 0
