#!/bin/bash
# Date: 2016-01-08
# Author: Liudian
#定期清理数据库中的user_model表中的过期数据
current_time=$(date +%s)
limit_time=$[90*24*60*60]
time_line=$[${current_time}-${limit_time}]
log_file=/tmp/purge_user_model.log

#小于$time_line的是早于90天的数据，删除user_model表中早于90天的数据（下载数据）
mysql -e "delete from oumoo_www.user_model where time < $time_line;"
[ $? -eq 0 ] && echo "$(date "+%F %T") purge table oumoo_www.user_model done." >> $log_file
