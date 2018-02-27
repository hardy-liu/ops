#!/usr/bin/env bash
# Author: liudian
# Date: 2016-05-26
# Function: Install php56 from repo

ifRemi=$(yum repolist | grep "^remi" | wc -l)		#是否安装的remi的php源
remiName='remi-release-7.rpm'						#remi的repo软件包名称
fpmPort='9000'										#php-fpm的监听端口
fpmUser='nginx'										#php-fpm的执行用户
php56ConfDir='/opt/remi/php56/root/etc'				#php56配置文件目录
php56RootDir='/opt/remi/php56/root'				
php56SessionDir='/data/php_session/php56'			#php56的session文件存放目录
php56LogDir='/data/log/php-fpm'						#fpm日志目录
php56Packages=(php56-php php56-php-gd php56-php-xmlrpc php56-php-pecl-redis php56-php-pdo php56-php-mbstring php56-php-mysql php56-php-fpm php56-php-bcmath php56-php-mcrypt php56-php-soap)

function install_epel() {
	yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
}

#检查remi源是否安装
function check_repo() {
	[[ $ifRemi -eq 0 ]] && rpm -ivh http://www.hardyliu.me/packages/rpm/php/${remiName}
}

#安装php56
function install_php56() {
	for i in ${php56Packages[*]}; do
		yum install -y $i
		[[ ! $? -eq 0 ]] && exit 1
	done
}

#更改php56的php.ini配置
function modify_php56_ini() {
	[[ ! -f ${php56ConfDir}/php.ini.default ]] && \
	cp ${php56ConfDir}/{php.ini,php.ini.default}

	for i in ${php56ConfDir}/php.ini; do
		sed -i 's/post_max_size = 8M/post_max_size = 32M/' $i
        sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 32M/' $i
        sed -i 's/;date.timezone =/date.timezone = Asia\/Shanghai/' $i
        sed -i 's/max_execution_time = 30/max_execution_time = 300/' $i
		sed -i 's/expose_php = On/expose_php = Off/' $i
		sed -i 's/mysqli.default_socket =/mysqli.default_socket = \/data\/mysql\/mysql.sock/' $i
		sed -i 's/pdo_mysql.default_socket=/pdo_mysql.default_socket = \/data\/mysql\/mysql.sock/' $i
		sed -i 's/mysql.default_socket =/mysql.default_socket = \/data\/mysql\/mysql.sock/' $i
#		sed -i 's/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT/error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE/' $i
	done
}

#更改php56的php-fpm的配置
function modify_php_fpm() {
	[[ ! -f ${php56ConfDir}/php-fpm.d/www.conf.default ]] && \
	cp ${php56ConfDir}/php-fpm.d/{www.conf,www.conf.default}

	for i in ${php56ConfDir}/php-fpm.d/www.conf; do
		sed -i "s/listen = 127.0.0.1:9000/listen = 127.0.0.1:${fpmPort}/" $i
		sed -i "s/user = apache/user = ${fpmUser}/" $i
		sed -i "s/group = apache/group = ${fpmUser}/" $i
		sed -i 's/pm.max_children = 50/pm.max_children = 500/' $i
		sed -i 's/;request_slowlog_timeout = 0/request_slowlog_timeout = 3/' $i
		sed -i "s@slowlog = ${php56RootDir}/var/log/php-fpm/www-slow.log@slowlog = ${php56LogDir}/www-slow.log@" $i
		sed -i "s@php_admin_value\[error_log\] = ${php56RootDir}/var/log/php-fpm/www-error.log@php_admin_value\[error_log\] = ${php56LogDir}/www-error.log@" $i
		sed -i "s@php_value\[session.save_path\]    = ${php56RootDir}/var/lib/php/session@php_value\[session.save_path\]    = ${php56SessionDir}@" $i
		sed -i 's/;catch_workers_output = yes/catch_workers_output = yes/' $i
	done	
	
    [[ ! -f ${php56ConfDir}/php-fpm.conf.default ]] && \
    cp ${php56ConfDir}/{php-fpm.conf,php-fpm.conf.default}

	for i in ${php56ConfDir}/php-fpm.conf; do
		sed -i "s@error_log = ${php56RootDir}/var/log/php-fpm/error.log@error_log = ${php56LogDir}/error.log@" $i
	done
	
	[[ ! -d ${php56LogDir} ]] && mkdir -p ${php56LogDir}

	#创建php-fpm执行用户nginx，并更改session目录为nginx
    if ! id ${fpmUser} &> /dev/null; then
        useradd -r -s /sbin/nologin $fpmUser
    fi
	[[ ! -d ${php56SessionDir} ]] && mkdir -p ${php56SessionDir}
	chown -R ${fpmUser}.${fpmUser} ${php56SessionDir}
}

#修改默认的php命令执行程序为php56
function php54_to_php56() {
	if [[ -f /usr/bin/php ]]; then
		if [[ ! -h /usr/bin/php ]]; then 
	#如果/usr/bin/php文件存在且不为符号链接时，说明/usr/bin/php文件为php54的bin文件
			mv /usr/bin/{php,php54}
			ln -sv /usr/bin/{php56,php}
		fi
	#当/usr/bin/php文件不存在时，说明php54未安装，之间创建符号链接即可
	else 
		ln -sv /usr/bin/{php56,php}
	fi
}

#启动php-fpm进程
function start_php_fpm() {
	systemctl start php56-php-fpm.service
	systemctl enable php56-php-fpm.service
}

install_epel
check_repo
install_php56
modify_php56_ini
modify_php_fpm
php54_to_php56
start_php_fpm
