#!/bin/bash
# Date: 2016-03-01
scriptName=$(basename $0)
codeDir=/data/www/ddos/    				#防护宝代码根目录
confDir=/data/uploads/          		#配置文件上传目录
venderDir="/data/vender_uploads/"		#供应商logo图片上传目录
autoScriptDir="/data/shell/auto/"   	#后台脚本目录
logFile=/data/log/${scriptName%.*}.log  #输出日志

#日志记录函数，第一个参数为日志信息，第二个参数为日志文件
write_log() {
    echo "$(date "+%F %T") $1" >> $2
}

#创建配置文件上传目录
create_vhosts_dir() {
    if [[ ! -d $confDir ]];then
        mkdir -p $confDir && write_log "$confDir not exists, created." $logFile
    else 
        write_log "$confDir exists, nothind to do." $logFile
    fi
}

#创建代理商及logo图片上传目录及相关符号链接
create_vender_slink() {
	#创建vender_uploads目录
	if [[ ! -d $venderDir ]]; then
		mkdir -p ${venderDir}img/header/ && \
        chown -R nginx.nginx $venderDir && \
		write_log "${venderDir}img/header/ not exists, created." $logFile
	else 
		write_log "${venderDir}img/header/ exists, nothing to do." $logFile
	fi

	#创建vender_uploads的符号链接
    if [[ ! -h ${codeDir}vender_uploads ]]; then
        ln -sv ${venderDir} ${codeDir}vender_uploads && \
        write_log "create symblo link ${codeDir}vender_uploads done." $logFile
    else 
        write_log "${codeDir}vender_uploads exists, nothind to do." $logFile
    fi

	#创建ueditor图片上传的符号链接
	if [[ ! -h ${codeDir}php/back/ueditor/header ]]; then
		ln -sv ${codeDir}vender_uploads/img/header/ ${codeDir}php/back/ueditor/header && \
		write_log "create symblo link 'php/back/ueditor/header' done." $logFile
	else 
		write_log "symbol link 'php/back/ueditor/header' exists, nothing to do." $logFile
	fi
}

#在代码目录下创建符号链接到配置文件上传目录
create_uploads_slink() {
    if [[ ! -h ${codeDir}uploads ]];then
        cd $codeDir
        ln -sv /data/uploads/ uploads && write_log "create symbol link 'uploads' done." $logFile
    else 
        write_log "symbol link 'uploads' exists, nothing to do." $logFile
    fi
}

#创建代码的配置文件（前台）
create_front_conf() {
    dbHost=192.168.40.200
    dbPass='720a6a530cb91b20'
    redisHost=127.0.0.1
    frontConfFile=${codeDir}php/prop/config.inc.php
    if [[ ! -f $frontConfFile ]];then
    cat > $frontConfFile << EOF
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
?>
EOF
        write_log "write configuration into $frontConfFile done." $logFile
    else 
        write_log "$frontConfFile exists, nothing to do." $logFile
    fi
}

#创建后台代码的配置文件
create_back_conf() {
    backConfFile=${codeDir}php/inc/config.inc.php
    if [[ ! -f $backConfFile ]];then
        cp $frontConfFile $backConfFile && \
        write_log "write configuration into $backConfFile done." $logFile
    else
        write_log "$backConfFile exits, nothing to do." $logFile
    fi
}

#清理代码的BOM头部
purge_BOM() {
    grep -r -I -l $'^\xEF\xBB\xBF' $codeDir | xargs sed -i 's/^\xEF\xBB\xBF//' &> /dev/null && \
    write_log "purge BOM done." $logFile || \
    write_log "no BOM, nothing to do." $logFile
}

#清除windows下的回车键
purge_CRLF() {
    grep -r -I -l "$" $codeDir | xargs sed -i 's/$//' &> /dev/null && \
    write_log "purge CR done."  $logFile || \
    write_log "no CR, nothing to do." $logFile
}

#配置代码的owner为nginx用户
change_code_owner() {
    chown -R nginx.nginx $codeDir && \
    chown -R nginx.nginx ${codeDir}uploads/ && \
    write_log "change codes owner to nginx.nginx done." $logFile
}

#配置supervisord来运行后台脚本
config_auto_scrpits() {
    if ! rpm -qi supervisor &> /dev/null; then
        yum install -y supervisor &> /dev/null && \
        write_log "install supervisor done." $logFile
    else 
        write_log "supervisor already installed, nothing to do." $logFile
    fi
    if [[ ! -f /etc/supervisord.d/ddos_auto.ini ]]; then
        cat > /etc/supervisord.d/ddos_auto.ini << EOF
[program:beian]
command=/bin/bash /data/shell/auto/%(program_name)s.sh
user=root
autostart=true
autorestart=true
startretries=3
stdout_logfile=/data/log/supervisord/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stderr_logfile=/data/log/supervisord/%(program_name)s_error.log 
stderr_logfile_maxbytes=10MB

[program:beian_ip]
command=/bin/bash /data/shell/auto/%(program_name)s.sh
user=root
autostart=true
autorestart=true
startretries=3
stdout_logfile=/data/log/supervisord/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stderr_logfile=/data/log/supervisord/%(program_name)s_error.log 
stderr_logfile_maxbytes=10MB

[program:count]
command=/bin/bash /data/shell/auto/%(program_name)s.sh
user=root
autostart=true
autorestart=true
startretries=3
stdout_logfile=/data/log/supervisord/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stderr_logfile=/data/log/supervisord/%(program_name)s_error.log 
stderr_logfile_maxbytes=10MB

[program:getip]
command=/bin/bash /data/shell/auto/%(program_name)s.sh
user=root
autostart=true
autorestart=true
startretries=3
stdout_logfile=/data/log/supervisord/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stderr_logfile=/data/log/supervisord/%(program_name)s_error.log 
stderr_logfile_maxbytes=10MB

[program:zonefirewallflow]
command=/bin/bash /data/shell/auto/%(program_name)s.sh
user=root
autostart=true
autorestart=true
startretries=3
stdout_logfile=/data/log/supervisord/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stderr_logfile=/data/log/supervisord/%(program_name)s_error.log 
stderr_logfile_maxbytes=10MB

[program:zonefirewallflow_ip]
command=/bin/bash /data/shell/auto/%(program_name)s.sh
user=root
autostart=true
autorestart=true
startretries=3
stdout_logfile=/data/log/supervisord/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stderr_logfile=/data/log/supervisord/%(program_name)s_error.log 
stderr_logfile_maxbytes=10MB

[program:zonelistdomain]
command=/bin/bash /data/shell/auto/%(program_name)s.sh
user=root
autostart=true
autorestart=true
startretries=3
stdout_logfile=/data/log/supervisord/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stderr_logfile=/data/log/supervisord/%(program_name)s_error.log 
stderr_logfile_maxbytes=10MB

[program:zonelist]
command=/bin/bash /data/shell/auto/%(program_name)s.sh
user=root
autostart=true
autorestart=true
startretries=3
stdout_logfile=/data/log/supervisord/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stderr_logfile=/data/log/supervisord/%(program_name)s_error.log 
stderr_logfile_maxbytes=10MB

[program:searchdns]
command=/bin/bash /data/shell/auto/%(program_name)s.sh
user=root
autostart=true
autorestart=true
startretries=3
stdout_logfile=/data/log/supervisord/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stderr_logfile=/data/log/supervisord/%(program_name)s_error.log
stderr_logfile_maxbytes=10MB

[program:dg_firewallflow_conn]
command=/bin/bash /data/shell/auto/%(program_name)s.sh
user=root
autostart=true
autorestart=true
startretries=3
stdout_logfile=/data/log/supervisord/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stderr_logfile=/data/log/supervisord/%(program_name)s_error.log 
stderr_logfile_maxbytes=10MB

[program:xm_firewallflow_conn]
command=/bin/bash /data/shell/auto/%(program_name)s.sh
user=root
autostart=true
autorestart=true
startretries=3
stdout_logfile=/data/log/supervisord/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stderr_logfile=/data/log/supervisord/%(program_name)s_error.log 
stderr_logfile_maxbytes=10MB

[program:send_text_message]
command=/bin/bash /data/shell/auto/%(program_name)s.sh
user=root
autostart=true
autorestart=true
startretries=3
stdout_logfile=/data/log/supervisord/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stderr_logfile=/data/log/supervisord/%(program_name)s_error.log 
stderr_logfile_maxbytes=10MB

[program:send_voice_message]
command=/bin/bash /data/shell/auto/%(program_name)s.sh
user=root
autostart=true
autorestart=true
startretries=3
stdout_logfile=/data/log/supervisord/%(program_name)s.log
stdout_logfile_maxbytes=10MB
stderr_logfile=/data/log/supervisord/%(program_name)s_error.log 
stderr_logfile_maxbytes=10MB
EOF
        write_log "add supervisor configure file done." $logFile
        systemctl enable supervisord
        systemctl restart supervisord
    else 
        write_log "supervisor configure file exists, nothing to do" $logFile
    fi
}

create_vhosts_dir
create_vender_slink
create_uploads_slink
create_front_conf
create_back_conf
purge_BOM
purge_CRLF
change_code_owner
config_auto_scrpits
