#!/usr/bin/env bash
# Function: 部署wx代码
# Date: 2016-05-30

codeDir="/data/www/$1"									#代码目录
logFile="/data/log/$(basename $0 | cut -d "." -f1).log"	#输出日志
confFile="${codeDir}/inc/config.inc.php"				#数据库连接配置文件
ignoredDir=('/api/version' '/api/adupload' '/api/uploadimg' '/api/webupload')
allowedArgs=('wx_dev_back' 'wx_dev_front')				#允许传递的参数

[[ ! -d $codeDir ]] && echo "$codeDir is not exists. exiting" && exit 1

#如果传递的不是指定的参数就退出
if ! echo "${allowedArgs[*]}" | grep -w "$1" &> /dev/null; then
	echo "invalid args.[wx_dev_back|wx_dev_front]"
	exit 2
fi

#记录日志
function write_log {
	echo "$(date "+%F %T") $1." >> $logFile
}

#创建图片上传等文件夹
function mk_ignored_dir {
	for i in ${ignoredDir[*]}; do
		if [[ ! -d ${codeDir}$i ]]; then
			mkdir -p ${codeDir}$i && \
			write_log "make dir ${codeDir}$i done."
		else 
			write_log "dir ${codeDir}$i already exists, nothing to do."
		fi
	done
}

#创建config.inc.php配置文件
function create_conf {
	dbHost='localhost'
	dbUser='wx_test'
	dbPass='newpasswd'
	dbName='wx_test'
	if [[ ! -f $confFile ]]; then
		cat > $confFile << EOF
<?php
\$dbhost = '${dbHost}';
\$dbuser = '${dbUser}';
\$dbpw = '${dbPass}';
\$dbname = '${dbName}';
\$pconnect = 0;
\$multiserver = array( );
\$database = 'mysql';
\$dbcharset = 'utf-8';
define('CHARSET', 'utf-8');
EOF
		write_log "create configuration $confFile done."
	else 
		write_log "$confFile already exists, nothing to do."
	fi
}

#清理代码文件的BOM头部
function purge_BOM() {
    grep -r -I -l $'^\xEF\xBB\xBF' $codeDir | xargs sed -i 's/^\xEF\xBB\xBF//' &> /dev/null && \
    write_log "purge BOM done." $logFile || \
    write_log "no BOM, nothing to do." $logFile
}

#清除windows下的回车键(CRLF)
function purge_CRLF() {
    grep -r -I -l "$" $codeDir | xargs sed -i 's/$//' &> /dev/null && \
    write_log "purge CRLF done."  $logFile || \
    write_log "no CRLF, nothing to do." $logFile
}

#更改代码文件的所有者为nginx用户
function change_code_owner {
	chown -R nginx.nginx $codeDir && \
	write_log "change codes owner to nginx.nginx done."
}

mk_ignored_dir
create_conf
purge_BOM
purge_CRLF
change_code_owner
