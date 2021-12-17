#!/bin/bash
# Author: liudian
# Date: 2016-05-04
# Function: 备份数据库

logFile='/data/log/db_backup.log'	#此脚本的输出日志
dbUser='root'						#备份数据库时mysqldump命令使用的账号
dbPass='newpasswd'					#备份数据库时mysqldump命令使用的密码
dbName=($*)							#需要备份的数据库，数组形式
bkDir='/data/backup/mysql/'			#备份文件的存放目录
bkSuffix="_$(date +%F).sql.gz"		#备份文件的后缀
bkExpiration=30						#备份文件的最长保存时间，以天为单位
dbHost='my-docker-mysql'
dbBinLog="$(mysql -u${dbUser} -p${dbPass} -h${dbHost} -e "show master status" | tail -1 | awk '{print $1}')"	#数据库当前的binlog

#备份数据库函数，接受数据库名作为参数
function db_backup() {
	mysqldump -u${dbUser} -p${dbPass} -h${dbHost} --databases $1 | \
	gzip > ${bkDir}${1}${bkSuffix} && \
	echo "$(date "+%F %T") backup datebase $1 done." >> $logFile || \
	exit 10
}

#刷新数据库binlog函数
function db_flushlog() {
	mysql -u${dbUser} -p${dbPass} -h${dbHost} -e "flush logs;" && \
	mysql -u${dbUser} -p${dbPass} -h${dbHost} -e "purge binary logs to '${dbBinLog}';" && \
	echo "$(date "+%F %T") purge binary logs to ${dbBinLog} done." >> $logFile || \
	exit 20
}

#清理过期的备份文件函数
function purge_backup() {
	local i
	for i in $(find $bkDir -mtime $bkExpiration); do
		rm -rf $i && \
		echo "$(date "+%F %T") delete outdated backup file $i done." >> $logFile
	done
}

[[ ! -d $(dirname $logFile) ]] && mkdir -p $(dirname $logFile)
[[ ! -d $bkDir ]] && mkdir -p $bkDir

#备份数据库
for i in ${dbName[*]}; do
	db_backup $i
done

db_flushlog
purge_backup
