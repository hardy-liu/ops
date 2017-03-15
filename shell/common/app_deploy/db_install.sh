#!/bin/bash
# Author: liudian
# Date: 20161015
# Function: yum安装mariadb，并优化配置

dbPackages=(mariadb mariadb-server)
dbConf='/etc/my.cnf'		#mysql配置文件
dbDataDir='/data/mysql'		#mysql数据目录
dbLogDir='/data/log/mysql'	#mysql日志存放目录（错误日志和慢日志）
#innodb buffer缓存设置为内存总量的一半
innodbBufferSize="$(($(cat /proc/meminfo | grep "MemTotal" | awk '{print $2}') / 2))KB"

function install_db {
    local i
    for i in ${dbPackages[*]}; do
        yum install -y $i
    done
}

function check_dir {
	[[ ! -d $dbDataDir ]] && mkdir -p $dbDataDir
	[[ ! -d $dbLogDir ]] && mkdir -p $dbLogDir
	chown -R mysql.mysql $dbDataDir
	chown -R mysql.mysql $dbLogDir
}

function configure_db {
	local i
	if [[ ! -f ${dbConf}.default ]]; then
		cp ${dbConf} ${dbConf}.default
	fi
	
	for i in ${dbConf}; do
		sed -i "s@datadir=/var/lib/mysql@datadir=${dbDataDir}@" $i
		sed -i "s@socket=/var/lib/mysql/mysql.sock@socket=${dbDataDir}/mysql.sock@" $i
		sed -i "s@log-error=/var/log/mariadb/mariadb.log@log-error=${dbLogDir}/mariadb.log@" $i
		sed -i "/\[mysqld\]/i \\
[client]\\n\
port = 3306\\n\
socket = ${dbDataDir}/mysql.sock\\n\
default-character-set = utf8\\n\
\\n" $i
		sed -i "/\[mysqld_safe\]/i \\
\#关闭名称解析\\n\
skip-name-resolve = ON\\n\
\\n\
\#开启二进制日志，且指定日志前缀名\\n\
log-bin = mariadb-bin\\n\
expire_logs_days = 15\\n\
\\n\
\#设置默认的字符集为utf8，新建数据库继承此属性\\n\
character_set_server = utf8\\n\
\\n\
\#允许的最大连接数\\n\
max_connections = 1024\\n\
\#默认值1M，控制通信缓冲区的最大长度，SQL语句过大或者语句中含有BLOB或者longblob字段时，默认的缓冲可能不够\\n\
max_allowed_packet = 20M\\n\
\#是否启用查询缓存\\n\
query_cache_type = ON\\n\
\#不缓存大于此大小的结果，默认1M\\n\
query_cache_limit = 50M\\n\
\#定义查询缓存所使用的内存大小\\n\
query_cache_size = 512M\\n\
\\n\
\#启用慢日志\\n\
slow_query_log = ON\\n\
\#定义慢日志的存放路径\\n\
slow-query-log-file = ${dbLogDir}/slow.log\\n\
\#定义大于多少秒的查询纪录慢日志\\n\
long_query_time = 5\\n\
\\n\
\#设置innodb每表独立的表空间\\n\
innodb_file_per_table = 1\\n\
\#innodb可以使用的数据和索引cashe的总大小，默认128M，对于innodb来说，调大此参数可以极大提高性能\\n\
innodb_buffer_pool_size = $innodbBufferSize\\n\
\#innodb buffer pool会分割成多少个instance存储，提高并发性\\n\
innodb_buffer_pool_instances = 4\\n\
\\n\
\#myisam索引的缓存大小\\n\
key_buffer_size = 256M\\n\
\#保存在内存中的临时表的大小限制，group by操作优化\\n\
tmp_table_size = 512M\\n\
\#内存表的大小限制\\n\
max_heap_table_size = 512M\\n\
\\n" $i
	done
		
}

function start_service {
	if systemctl start mariadb &> /dev/null; then
		echo "start mariadb server ok."
		systemctl enable mariadb
	else 
		echo "start mariadb failed, please check log for more details."
	fi
}

install_db
check_dir
configure_db
start_service
