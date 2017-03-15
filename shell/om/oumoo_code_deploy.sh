#!/bin/bash
#Date: 2016-03-07
#欧模代码初始化脚本
#创建Cache目录
codeDir="/data/www/oumoo_api_test"
scriptName="$(basename $0)"
logFile="/tmp/${scriptName%.*}.log"

#日志记录函数，第一个参数为日志信息，第二个参数为日志文件
write_log() {
    echo "$(date "+%F %T") $1" >> $2
}

#创建Cache目录
if [[ ! -d ${codeDir}/Cache ]]; then
	mkdir -p ${codeDir}/Cache/{js,sitemap,xml} && write_log "Cache dir not exists, created." $logFile
else
	write_log "Cache dir exists, nothind to do." $logFile
fi

#创建Uploads符号链接，链接到存储
if [[ ! -h ${codeDir}/Uploads ]];then
    cd $codeDir
    ln -sv /data/data/www/Uploads Uploads && write_log "create symbol link 'Uploads' done." $logFile
else 
    write_log "symbol link 'Uploads' exists, nothing to do." $logFile
fi

#创建代码的配置文件
dbHost=localhost
confFile=${codeDir}/mysql/config.inc.php
if [[ ! -f $confFile ]];then
cat > $confFile << EOF
<?php
\$dbhost = "$dbHost";//localhost
\$dbuser = "root";//root
\$dbpw = "newpasswd";//newpasswd
\$dbname = "oumoo_test";
\$pconnect = 0;
\$multiserver = array( );
\$database = "mysql";
\$dbcharset = "utf8";
define( "CHARSET", "utf8" );
?>
EOF
    write_log "write configuration into $confFile done." $logFile
else 
    write_log "$confFile exists, nothing to do." $logFile
fi

#清理代码的BOM头部
grep -r -I -l $'^\xEF\xBB\xBF' $codeDir | xargs sed -i 's/^\xEF\xBB\xBF//' &> /dev/null \
&& write_log "purge BOM done." $logFile \
|| write_log "no BOM, nothing to do." $logFile

#清除windows下的回车键
grep -r -I -l "$" $codeDir | xargs sed -i 's/$//' &> /dev/null \
&& write_log "purge CR done."  $logFile \
|| write_log "no CR, nothing to do." $logFile

#配置代码的owner为nginx用户
chown -R apache.apache $codeDir && write_log "change codes owner to nginx.nginx done." $logFile

