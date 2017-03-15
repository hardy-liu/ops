#!/bin/bash
#运行在download（14.152.90.37）服务器上，定期备份
BAKDIR=/data/data/
BAKLOG=/root/script/nfs_bak.log
rsync -azHP --password-file=/etc/rsync.pas $BAKDIR rsyncuser@113.107.97.5::om_backup
[ $? -eq 0 ] && echo "NFS backup succeeded at `date +%F_%T` >> $BAKLOG
