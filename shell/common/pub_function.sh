#!/bin/bash
# Author: liudian
# Date: 2016-02-29
# Function: 公共函数

scriptName=$(basename $0)
logFile=/data/log/${scriptName%%.*}.log #生成log文件，log文件名与脚本文件同名，后缀为.log
maxLogSize=5	#设置日志文件的大小，单位为MB

#日志备份函数，判断日志文件是否超过指定的大小，如果超过则备份之，然后清空原来的日志文件
#此函数传递两个参数过去，第一个为日志文件，第二个问日志文件大小限制
purge_log_file() {
	local maxLogSize=$[$2 * 1024 * 1024]
	logSize=$(du -b $1 | awk '{print $1}')	
	logBakFile=${1}.gz

	if [[ $logSize -gt $maxLogSize ]];then
		cat $1 | gzip >  $logBakFile && echo -n "" > $1 #备份原来的日志文件并清空
	fi
}

#日志记录函数，第一个参数为日志信息，第二个参数为日志文件
write_log() {
    echo "$(date "+%F %T") $1" >> $2
}

purge_log_file $logFile $maxLogSize 
