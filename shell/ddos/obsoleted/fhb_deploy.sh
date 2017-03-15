#!/bin/bash
# Date: 2016-03-01
scriptName=$(basename $0)
codeDir=/data/www/fanghubao/    #防护宝代码根目录
confDir=/data/uploads/          #配置文件上传目录
venderDir="${codeDir}vender_uploads/img/header"  #供应商logo图片上传目录
autoScriptDir="/data/shell/auto/"   #后台脚本目录
logFile=/data/log/${scriptName%.*}.log   #输出日志

#日志记录函数，第一个参数为日志信息，第二个参数为日志文件
write_log() {
    echo "$(date "+%F %T") $1" >> $2
}

#创建配置文件上传目录
if [[ ! -d $confDir ]];then
    mkdir -p $confDir && write_log "$confDir not exists, created." $logFile
else 
    write_log "$confDir exists, nothind to do." $logFile
fi

#创建供应商logo上传目录
if [[ ! -d $venderDir ]];then
    mkdir -p $venderDir && write_log "$venderDir not exists, created." $logFile
else 
    write_log "$venderDir exists, nothind to do." $logFile
fi

#在代码目录下创建符号链接到配置文件上传目录
if [[ ! -h ${codeDir}uploads ]];then
    cd $codeDir
    ln -sv /data/uploads/ uploads && write_log "create symbol link 'uploads' done." $logFile
else 
    write_log "symbol link 'uploads' exists, nothing to do." $logFile
fi

#创建代码的配置文件（前台）
dbHost=192.168.40.200
redisHost=127.0.0.1
frontConfFile=${codeDir}php/prop/config.inc.php
if [[ ! -f $frontConfFile ]];then
cat > $frontConfFile << EOF
<?php
\$dbhost = "$dbHost";
\$dbuser = "fhb"; // 权限：select insert update delete
\$dbpw = "720a6a530cb91b20";
\$dbname = "fhb";
\$pconnect = 0;

\$multiserver = array( );
\$database = "mysql";
\$dbcharset = "utf8";
define( "CHARSET", "utf8" );
define( "REDIS_HOST", "$redisHost" );
define( "REDIS_PORT", "6379" );
?>
EOF
    write_log "write configuration into $frontConfFile done." $logFile
else 
    write_log "$frontConfFile exists, nothing to do." $logFile
fi

#创建后台代码的配置文件
backConfFile=${codeDir}php/inc/config.inc.php
if [[ ! -f $backConfFile ]];then
    cp $frontConfFile $backConfFile && \
    write_log "write configuration into $backConfFile done." $logFile
else
    write_log "$backConfFile exits, nothing to do." $logFile
fi

#清理代码的BOM头部
grep -r -I -l $'^\xEF\xBB\xBF' $codeDir | xargs sed -i 's/^\xEF\xBB\xBF//' &> /dev/null && \
write_log "purge BOM done." $logFile || \
write_log "no BOM, nothing to do." $logFile

#清除windows下的回车键
grep -r -I -l "$" $codeDir | xargs sed -i 's/$//' &> /dev/null && \
write_log "purge CR done."  $logFile || \
write_log "no CR, nothing to do." $logFile

#配置代码的owner为nginx用户
chown -R nginx.nginx $codeDir && \
chown -R nginx.nginx ${codeDir}uploads/ && \
write_log "change codes owner to nginx.nginx done." $logFile

#配置supervisord来运行后台脚本
if ! rpm -qi supervisor &> /dev/null; then
    yum install -y supervisor &> /dev/null && \
    write_log "install supervisor done." $logFile
else 
    write_log "supervisor already installed, nothing to do." $logFile
fi
if [[ ! -f /etc/supervisord.d/fhb_auto.ini ]]; then
    cat > /etc/supervisord.d/fhb_auto.ini << EOF
[program:beian]
command=/bin/bash /data/shell/auto/beian.sh
user=root
autostart=true
autorestart=true
startretries=3

[program:count]
command=/bin/bash /data/shell/auto/count.sh
user=root
autostart=true
autorestart=true
startretries=3

[program:firewallflow_conn]
command=/bin/bash /data/shell/auto/firewallflow_conn.sh
user=root
autostart=true
autorestart=true
startretries=3

[program:getip]
command=/bin/bash /data/shell/auto/getip.sh
user=root
autostart=true
autorestart=true
startretries=3

[program:zonefirewallflow]
command=/bin/bash /data/shell/auto/zonefirewallflow.sh
user=root
autostart=true
autorestart=true
startretries=3

[program:zonelistdomain]
command=/bin/bash /data/shell/auto/zonelistdomain.sh
user=root
autostart=true
autorestart=true
startretries=3

[program:zonelist]
command=/bin/bash /data/shell/auto/zonelist.sh
user=root
autostart=true
autorestart=true
startretries=3

[program:searchdns]
command=/bin/bash /data/shell/auto/searchdns.sh
user=root
autostart=true
autorestart=true
startretries=3

[program:onefirewallflow_conn]
command=/bin/bash /data/shell/auto/onefirewallflow_conn.sh
user=root
autostart=true
autorestart=true
startretries=3

[program:twofirewallflow_conn]
command=/bin/bash /data/shell/auto/twofirewallflow_conn.sh
user=root
autostart=true
autorestart=true
startretries=3
EOF
    write_log "add supervisor configure file done." $logFile
    systemctl enable supervisord
    systemctl restart supervisord
else 
    write_log "supervisor configure file exists, nothing to do" $logFile
fi
