#!/usr/bin/env bash
# Author: liudian
# Date: 2016-06-04
# Function: 归档nginx日志文件

ngxLogDir='/data/log/nginx'									        #nginx日志存放目录
ngxLogBkDir='/data/backup/nginx'							        #nginx日志备份目录
ngxBkLogPrefix="$(date +%F)_"								        #nginx日志备份后缀名
ngxBkLogExpire='30'											        #nginx备份日志的过期时间
logFile="/data/log/shell/$(basename $0 | cut -d '.' -f1).log"		#脚本执行输出日志

#创建目录
[[ ! -d ${ngxLogBkDir} ]] && mkdir -p ${ngxLogBkDir}
[[ ! -d $(dirname $logFile) ]] && mkdir -p $(dirname $logFile)

#备份nginx日志
function log_rotate () {
    local i															#日志文件名
	
    for i in $(ls ${ngxLogDir}); do
    	local ngxLogFile=${ngxLogDir}/$i							#待备份的日志文件名
      	local ngxBkLogFile=${ngxLogBkDir}/${ngxBkLogPrefix}${i}.gz	#备份日志的全路径名
		
		if [[ -f ${ngxLogFile} ]]; then 							#如果有目录就过滤掉
			cat $ngxLogFile | gzip > $ngxBkLogFile
			[[ $? -eq 0 ]] && echo '' > $ngxLogFile
			echo "$(date "+%F %T") archive $i into $ngxBkLogFile done." >> $logFile
		fi
    done
}

#清理过期的日志文件
function purge_expired_bklog() {
    local i
	
    for i in $(find ${ngxLogBkDir} -type f -mtime +${ngxBkLogExpire}); do
        rm -f $i && echo -e "$(date "+%F %T") delete $i done." >> $logFile
    done
}

log_rotate
purge_expired_bklog
