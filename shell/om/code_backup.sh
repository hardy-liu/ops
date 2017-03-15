#!/bin/bash
# Function: 备份fhb代码
# Data: 20160407

logFile='/data/log/code_backup.log'		#日志文件所在路径
codeName='fanghubao'					#代码所在目录名
codeDir='/data/www'						#代码所在目录的上一级目录
backDir="/data/code_backup/$codeName"	#代码备份保存的目录
backFileName="${backDir}/${codeName}_$(date +%Y%m%d).tar.gz"	#备份代码的文件名

write_log() {
    echo "$(date "+%F %T") $1" >> $logFile
}

#删除超过15天的备份文件
purge_outdated_files() {
	cd $backDir
	find ./ -mtime +15 | xargs rm -rf &> /dev/null
}

#备份代码
[[ ! -d $backDir ]] && mkdir -p $backDir
tar czf $backFileName -C $codeDir $codeName && \
write_log "code backup done."

#上传备份到欧模backup服务器
rsyncPassFile='/etc/rsync.pas'
rsyncUser='rsyncuser'
rsyncServer='113.107.97.5'
rsyncModule='code_backup'
[[ ! -f $rsyncPassFile ]] && echo 'password' > $rsyncPassFile && chmod 600 $rsyncPassFile
rsync -azHP --delete --password-file=${rsyncPassFile} $backDir ${rsyncUser}@${rsyncServer}::${rsyncModule} &> /dev/null && \
write_log "upload backup files to backup-server done."

purge_outdated_files
