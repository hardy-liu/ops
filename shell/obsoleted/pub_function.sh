#!/bin/bash
# Function: 公共函数

#日志备份函数，判断日志文件是否超过指定的大小，如果超过则备份之，然后清空原来的日志文件
#接受一个参数，绝对路径形式的日志文件
purge_log_file() {
	local maxLogSize=$[10 * 1024 * 1024] #日志文件大小为10MB
	local logSize=$(du -b $1 | awk '{print $1}') #传递过来的日志文件的大小
	local logBakFile=${1%%.log}_$(date +%Y%m%d-%H:%M).log.gz #备份日志的文件名

	if [[ $logSize -gt $maxLogSize ]];then
		cat $1 | gzip >  $logBakFile && echo -n "" > $1 #备份原来的日志文件并清空
	fi
}

#日志记录函数，第一个参数为日志信息，第二个参数为日志文件
write_log() {
	purge_log_file $2 #判断日志文件是否超过指定大小
    echo "$(date "+%F %T") $1" >> $2
}
