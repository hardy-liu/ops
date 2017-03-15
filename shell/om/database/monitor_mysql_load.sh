#!/bin/bash
# Date: 2016-02-29
# 监控cpu和mysql数据库线程，超过阈值之后重启mysql并发送邮件
scriptName=$(basename $0)
logFile=/data/log/${scriptName%%.*}.log	#生成log文件，log文件名与脚本文件同名，后缀为.log
maxLogSize=5	#设置日志文件的大小，单位为MB

#此函数传递两个参数过去，第一个为日志文件，第二个问日志文件大小限制
purge_log_file() {
	local maxLogSize=$[$2 * 1024 * 1024]
	logSize=$(du -b $1 | awk '{print $1}')	
	logBakFile=${1}.gz

	if [[ $logSize -gt $maxLogSize ]];then
		cat $1 | gzip >  $logBakFile && echo -n "" > $1 #备份原来的日志文件并清空
	fi
}

a=$(uptime | awk '{print $10}') #临时变量
cpuLoad=${a%,}
#当CPU负载超过16.0的时候发送报警邮件，并重启mariadb
if [[ $(echo "$cpuLoad > 16.00" | bc) -eq 1  ]];then
	echo "$(date "+%F %T") cpu load is:$cpuLoad, overload." >> $logFile
	echo "cpu overload." | mail -s "om db server warnning" liudian@tj.com \
	&& systemctl restart mariadb \
	&& echo "$(date "+%F %T") cpu load is:$cpuLoad. restart mariadb OK. sent email OK." >> $logFile;exit
else 
	echo "$(date "+%F %T") cpu load is:$cpuLoad." >> $logFile
fi

mysqlProcesses=$(mysqladmin processlist | wc -l)
#当mysql的进程数超过150的时候发送邮件，并重启mariadb
if [[ $mysqlProcesses -gt 150 ]];then
	echo "$(date "+%F %T") mysql processes is:$mysqlProcesses" >> $logFile
	echo "mysql overload." | mail -s "om db server warnning" liudian@tj.com \
	&& systemctl restart mariadb \
	&& echo "$(date "+%F %T") mysql processes is:$mysqlProcesses. restart mariadb OK. sent email OK." >> $logFile
else
	echo "$(date "+%F %T") mysql processes is:$mysqlProcesses" >> $logFile
fi

purge_log_file $logFile $maxLogSize 
