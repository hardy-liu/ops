#!/bin/bash
#
# Author: Liudian
# Date: 2015-12-31
# 备份oumoo和forum数据库
db_user=serveradmin
db_passwd=tuju_serveradmin
db=(oumoo_www oumoo_forum)
bk_dir=/data/backup/oumoo
bk_db_suffix=_$(date +%d).sql
bk_db_dir=$bk_dir/$(date +%Y-%m)
bk_log=$bk_dir/mysql_backup.log
db_bk_time_limit=10
db_bin_log=$(mysql -u${db_user} -p${db_passwd} -e "show master status" | tail -1 | awk '{print $1}')

#$1=db_name, $2=$bk_db_dir/${db_name}${bk_db_suffix}, $3=$bk_log
db_backup() {
    mysqldump -u$db_user -p$db_passwd --master-data=2 --databases $1 > $2
    [ $? -eq 0 ] && [ -f $2 ] && gzip $2
    [ $? -eq 0 ] && echo "$(date "+%F %T") backup datebase $1 done." >> $3 || exit 1
}

db_flushlog() {
    mysql -u$db_user -p$db_passwd -e "flush logs;"
    if [ $? -eq 0 ]; then
        mysql -u$db_user -p$db_passwd -e "purge binary logs to '${db_bin_log}';" \
	&& echo "$(date "+%F %T") purge binary logs to ${db_bin_log} done." >> $1
    else
        echo "flush log error. exiting" >> $1
        exit 10
    fi
}

#$1=$bk_dir, $2=key_word, $3=time_limit(days), $4=$bk_log
purge_bkfile() {
    local i
    for i in $(find $1 -name "${2}*" -mtime +$3); do
      rm -f $i && echo "$(date "+%F %T") delete outdated backup file $i done." >> $4
    done
}

#$1=$bk_dir, $2=$bk_log
purge_empty_dir() {
    local i
    local if_empty
    for i in $(find $1 -type d); do
      if_empty=$(ls $i)
	if [ "$if_empty" == "" ]; then	
	  rmdir $i && echo "$(date "+%F %T") detele the empty dir $i done." >> $2
	fi
    done
}

#backup database
[ ! -d $bk_db_dir ] && mkdir -p $bk_db_dir
for i in $(seq 0 $[${#db[*]}-1]);do
    db_backup ${db[$i]} ${bk_db_dir}/${db[$i]}${bk_db_suffix} $bk_log
done

db_flushlog ${bk_log}

for i in $(seq 0 $[${#db[*]}-1]);do
    purge_bkfile $bk_dir ${db[$i]} $db_bk_time_limit $bk_log
done

purge_empty_dir $bk_dir $bk_log

#upload backup to the backup_server
rsync_pass_file=/etc/rsync.pas
rsync_server=113.107.97.5
rsync_module=db_backup
rsync -azHP --delete --password-file=$rsync_pass_file $bk_dir rsyncuser@$rsync_server::$rsync_module &> /dev/null
[ $? -eq 0 ] && echo "$(date "+%F %T") upload $bk_dir to backup_server done." >> $bk_log
