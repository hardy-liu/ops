#!/usr/bin/env bash
# Function: ddos代码环境部署
# Date: 2016-06-06
# Usage: <scriptname> codeDir projectName

codeDir="/data/www/$1"				#ddos代码目录
confUpDir='/data/uploads'			#配置文件生成目录
picUpDir='/data/vender_uploads'		#后台图片上传目录
autoScriptDir='/data/shell/auto'	#后台脚本目录
allowedProject=('ddos' 'ddos_back' 'ddos_agent')
logFile="/data/log/ddos_deploy_${2}.log"

if [[ ! -d $codeDir ]]; then
	echo "$codeDir not exist."
	exit 1
fi

if ! echo "${allowedProject[*]}" | grep -w "$2" &> /dev/null; then
	echo "invalid args"
	exit 2
fi

#记录操作日志
function log {
	echo "$(date "+%F %T") $1" >> $logFile
}

#在代码目录下创建指向${confUpDir}的符号链接
function create_uploads_slink {
	if [[ ! -h ${codeDir}/uploads ]]; then
		ln -sv $confUpDir ${codeDir}/uploads && \
		log "create symbol link ${codeDir}/uploads done."
	fi
}

#在代码目录下创建指向${picUpDir}的符号链接
function create_vender_slink {
	if [[ ! -h ${codeDir}/vender_uploads ]]; then
		ln -sv $picUpDir ${codeDir}/vender_uploads && \
		log "create symbol link ${codeDir}/vender_uploads done."	
	fi

	if [[ ! -h ${codeDir}/php/back/ueditor/header ]]; then
		ln -sv ${codeDir}/vender_uploads/img/header/ ${codeDir}/php/back/ueditor/header && \
		log "create symbol link ${codeDir}/php/back/ueditor/header done."
	fi
}

#创建配置文件
function create_conf {
	dbHost='127.0.0.1'
    dbPass='newpasswd'
    redisHost='127.0.0.1'
    confFile="${codeDir}/php/prop/config.inc.php"

    if [[ ! -f $confFile ]];then
		cat > $confFile << EOF
<?php
\$dbhost = "$dbHost";
\$dbuser = "ddos"; // 权限：select insert update delete
\$dbpw = "$dbPass";
\$dbname = "ddos";
\$pconnect = 0;

\$multiserver = array( );
\$database = "mysql";
\$dbcharset = "utf8";
define( "CHARSET", "utf8" );
define( "REDIS_HOST", "$redisHost" );
define( "REDIS_PORT", "6379" );
EOF
		[[ $? -eq 0 ]] && log "write configuration into $confFile done."
	else 
		log "$confFile exists, nothing to do."	
	fi
}

#清理代码的BOM头部
purge_BOM() {
    grep -r -I -l $'^\xEF\xBB\xBF' $codeDir | xargs sed -i 's/^\xEF\xBB\xBF//' &> /dev/null && \
    log "purge BOM done." || \
    log "no BOM, nothing to do." 
}

#清除windows下的回车键
purge_CRLF() {
    grep -r -I -l "$" $codeDir | xargs sed -i 's/$//' &> /dev/null && \
    log "purge CR done."  || \
    log "no CR, nothing to do."
}

#配置代码的owner为nginx用户
change_code_owner() {
    chown -R nginx.nginx $codeDir && \
    log "change codes owner to nginx.nginx done." 
}

create_uploads_slink
if [[ ! $2 == 'ddos_agent' ]]; then
	create_vender_slink
fi
create_conf
purge_BOM
purge_CRLF
change_code_owner
