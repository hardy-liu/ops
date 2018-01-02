#!/usr/bin/env bash
# Author: liudian
# Date: 2017-11-07
# Function: Install php71 from repo

fpmUser='nginx'										#php-fpm的执行用户
fpmPort='9000'										#php-fpm的监听端口
php71ConfDir='/etc'									#php71配置文件目录
php71SessionDir='/data/php_session/php71'			#php71的session文件存放目录
php71LogDir='/data/log/php-fpm'						#fpm日志目录
php71Packages=(php php-gd php-xmlrpc php-pecl-redis php-pdo php-mbstring php-mysql php-fpm php-bcmath php-soap)

function install_remi() {
	rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	rpm -ivh http://rpms.remirepo.net/enterprise/remi-release-7.rpm
	yum install -y yum-utils
	yum-config-manager --enable remi-php71
}

#安装php71
function install_php71() {
	for i in ${php71Packages[*]}; do
		yum install -y $i
		[[ ! $? -eq 0 ]] && exit 1
	done
}

#更改php71的php.ini配置
function modify_php71_ini() {
	[[ ! -f ${php71ConfDir}/php.ini.default ]] && \
	cp ${php71ConfDir}/{php.ini,php.ini.default}

	for i in ${php71ConfDir}/php.ini; do
		sed -i 's/post_max_size = 8M/post_max_size = 32M/' $i
        sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 32M/' $i
        sed -i 's/;date.timezone =/date.timezone = Asia\/Shanghai/' $i
        sed -i 's/max_execution_time = 30/max_execution_time = 300/' $i
		sed -i 's/expose_php = On/expose_php = Off/' $i
		sed -i 's/mysqli.default_socket =/mysqli.default_socket = \/data\/mysql\/mysql.sock/' $i
		sed -i 's/pdo_mysql.default_socket=/pdo_mysql.default_socket = \/data\/mysql\/mysql.sock/' $i
#		sed -i 's/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE/' $i
	done
}

#更改php71的php-fpm的配置
function modify_php_fpm() {
	[[ ! -f ${php71ConfDir}/php-fpm.d/www.conf.default ]] && \
	cp ${php71ConfDir}/php-fpm.d/{www.conf,www.conf.default}

	for i in ${php71ConfDir}/php-fpm.d/www.conf; do
		sed -i "s/listen = 127.0.0.1:9000/listen = 127.0.0.1:${fpmPort}/" $i
		sed -i "s/user = apache/user = ${fpmUser}/" $i
		sed -i "s/group = apache/group = ${fpmUser}/" $i
		sed -i 's/pm.max_children = 50/pm.max_children = 500/' $i
		sed -i 's/;request_slowlog_timeout = 0/request_slowlog_timeout = 3/' $i
		sed -i "s@slowlog = /var/log/php-fpm/www-slow.log@slowlog = ${php71LogDir}/www-slow.log@" $i
		sed -i "s@php_admin_value\[error_log\] = /var/log/php-fpm/www-error.log@php_admin_value\[error_log\] = ${php71LogDir}/www-error.log@" $i
		sed -i "s@php_value\[session.save_path\]    = /var/lib/php/session@php_value\[session.save_path\]    = ${php71SessionDir}@" $i
		sed -i 's/;catch_workers_output = yes/catch_workers_output = yes/' $i
	done	
	
    [[ ! -f ${php71ConfDir}/php-fpm.conf.default ]] && \
    cp ${php71ConfDir}/{php-fpm.conf,php-fpm.conf.default}

	for i in ${php71ConfDir}/php-fpm.conf; do
		sed -i "s@error_log = /var/log/php-fpm/error.log@error_log = ${php71LogDir}/error.log@" $i
	done
	
	[[ ! -d ${php71LogDir} ]] && mkdir -p ${php71LogDir}

	#创建php-fpm执行用户nginx，并更改session目录为nginx
    if ! id ${fpmUser} &> /dev/null; then
        useradd -r -s /sbin/nologin $fpmUser
    fi
	[[ ! -d ${php71SessionDir} ]] && mkdir -p ${php71SessionDir}
	chown -R ${fpmUser}.${fpmUser} ${php71SessionDir}
}

#启动php-fpm进程
function start_php_fpm() {
	systemctl start php-fpm.service
	systemctl enable php-fpm.service
}

install_remi
install_php71
modify_php71_ini
modify_php_fpm
start_php_fpm
