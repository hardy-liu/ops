#!/usr/bin/env bash
# Author: Hardy
# Date: 2016-05-24
# Function: install php-5.6.30 from source
# Prerequisite: mysql


packageDir='/data/packages'						#tar包存放目录
phpVersion='php-5.6.30'							#php版本号
phpPackage="${packageDir}/${phpVersion}.tar.gz"	#php软件包名称
phpPrefix='/opt'								#php安装目录
phpConfDir="${phpPrefix}/etc/php"				#php配置文件目录
cpuNum=$(grep -c "processor" /proc/cpuinfo)		#CPU核心数，编译并行数量
sessionDir="${phpPrefix}/${phpVersion}/session"	#session目录
fpmUser='nginx'									#php-fpm执行用户
mysqlDir=$(which mysql)							#mysql安装目录
mysqlConfig=$(which mysql_config)				#mysql_config所在路径
logFile='/tmp/php_install_rhel7.log'			#日志输出文件
dependPackages=(libxml2-devel openssl-devel libcurl-devel bzip2-devel libpng-devel t1lib-devel gmp-devel libmcrypt-devel readline-devel libxslt-devel freetype-devel libXpm-devel libjpeg-turbo-devel)

#检查安装环境
function check_environment {
	#如果没安装mysql就退出
	if ! which mysqld_safe &> /dev/null; then
		echo "install mysql first." 
		exit 1
	fi

	#安装epel源
	ifEpel=$( yum repolist | grep epel |wc -l)
	[[ $ifEpel -eq 0 ]] && yum -y install http://mirrors.yun-idc.com/epel/epel-release-latest-7.noarch.rpm

	#创建php软件安装目录
	[[ ! -d $phpConfDir ]] && mkdir -p $phpConfDir

	#下载并解压缩tar包
	[[ ! -d $packageDir ]] && mkdir -p $packageDir
	[[ -d ${packageDir}/${phpVersion} ]] && rm -rf ${packageDir}/${phpVersion}

	cd $packageDir
	[[ ! -f $phpPackage ]] && curl -O http://www.hardyliu.me/packages/tar/php/${phpVersion}.tar.gz
	tar zxf $phpPackage || exit 2

}

#安装依赖包
function check_dependency {
	yum groupinstall -y --skip-broken "Compatibility Libraries" "Development Tools"
	for i in ${dependPackages[*]}; do
		yum install -y $i
	done
}

#编译安装php
function install_php {
	cd ${packageDir}/${phpVersion}

	make clean
	./configure \
		--prefix=${phpPrefix}/${phpVersion} \
		--sysconfdir=${phpConfDir} \
		--with-config-file-path=${phpConfDir} \
		--with-config-file-scan-dir=${phpConfDir}/php.d \
		--enable-bcmath \
		--enable-fpm \
		--with-fpm-user=$fpmUser \
		--with-fpm-group=$fpmUser \
		--with-bz2 \
		--enable-calendar \
		--with-curl \
		--enable-exif \
		--enable-ftp \
		--with-gd \
		--enable-gd-native-ttf \
		--with-gettext \
		--with-jpeg-dir=/usr/lib64 \
		--with-freetype-dir=/usr/lib64 \
		--with-xpm-dir=/usr/lib64 \
		--with-gmp \
		--enable-mbstring \
		--with-mcrypt \
		--with-mhash \
		--with-mysql \
		--with-mysql-sock \
		--with-mysqli=${mysqlConfig} \
		--with-pdo-mysql=${mysqlDir} \
		--with-openssl \
		--enable-opcache \
		--enable-pcntl \
		--with-pcre-regex \
		--with-readline \
		--enable-shmop \
		--enable-sockets \
		--enable-sysvmsg \
		--enable-sysvsem \
		--enable-sysvshm \
		--enable-static \
		--enable-soap \
		--with-t1lib \
		--enable-wddx \
		--with-xmlrpc \
		--with-xsl \
		--enable-zip \
		--with-zlib

	make -j ${cpuNum} && make install
	[[ ! $? -eq 0 ]] && exit 3
}

#执行安装后相关配置
function do_configuration {
	cd ${packageDir}/${phpVersion}

	#建立软链接
	[[ ! -h ${phpPrefix}/php ]] && ln -sv ${phpPrefix}/${phpVersion} ${phpPrefix}/php

	#创建php-fpm执行用户
	if ! id nginx &> /dev/null; then
		useradd -r -s /sbin/nologin $fpmUser
	fi

	#创建session保存目录
	mkdir -p -m 770 $sessionDir	
	chown -R root.$fpmUser $sessionDir
	
	#建立配置文件
	mkdir ${phpConfDir}/php.d
	cp php.ini-production ${phpConfDir}/php.ini
	cp ${phpConfDir}/{php-fpm.conf.default,php-fpm.conf}
	cp sapi/fpm/php-fpm.service /usr/lib/systemd/system	

	#修改php-fpm.service服务脚本
	sed -i "s:\${prefix}:${phpPrefix}/php:" /usr/lib/systemd/system/php-fpm.service
	sed -i "s:\${exec_prefix}:${phpPrefix}/php:" /usr/lib/systemd/system/php-fpm.service

	#修改php.ini配置文件
	cp ${phpConfDir}/{php.ini,php.ini.default}
	for i in ${phpConfDir}/php.ini; do
		sed -i 's/post_max_size = 8M/post_max_size = 32M/g' $i
		sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 32M/g' $i
		sed -i 's/;date.timezone =/date.timezone = Asia\/Shanghai/g' $i
		sed -i 's/max_execution_time = 30/max_execution_time = 300/g' $i
		
		sed -i "s:;session.save_path = \"/tmp\":session.save_path = \"${sessionDir}\":g" $i
	done 

	#修改php-fpm.conf配置文件
	cp ${phpConfDir}/{php-fpm.conf,php-fpm.conf.default}
	for i in ${phpConfDir}/php-fpm.conf; do
		sed -i 's/pm.max_children = 5/pm.max_children = 500/g' $i
		sed -i 's/pm.start_servers = 2/pm.start_servers = 10/g' $i
		sed -i 's/pm.min_spare_servers = 1/pm.min_spare_servers = 10/g' $i
		sed -i 's/pm.max_spare_servers = 3/pm.max_spare_servers = 45/g' $i
		sed -i 's/expose_php = On/expose_php = Off/' $i
		sed -i 's/;listen.allowed_clients = 127.0.0.1/listen.allowed_clients = 127.0.0.1/g' $i
	done				

	#添加php命令到系统环境变量中
	echo "export PATH=\$PATH:${phpPrefix}/php/bin" > /etc/profile.d/php.sh
	echo "export PATH=\$PATH:${phpPrefix}/php/sbin" > /etc/profile.d/php-fpm.sh
	source /etc/profile.d/{php.sh,php-fpm.sh}
	ln -sv ${phpPrefix}/php/bin/php /usr/bin/php

	#启动服务
	systemctl daemon-reload
	systemctl start php-fpm.service
	systemctl enable php-fpm.service
}

#添加opcache模块
function add_opcache {
	echo -en "[opcache]\nzend_extension=opcache.so\nopcache.enable=1\nopcache.memory_consumption=128\nopcache.interned_strings_buffer=8\nopcache.revalidate_freq=5\nopcache.max_accelerated_files=5000\nopcache.fast_shutdown=1\nopcache.save_comments=0\n" > ${phpConfDir}/php.d/opcache.ini
	systemctl restart php-fpm.service
}

#编译安装php-pecl的redis扩展
function install_php_pecl_redis {
	cd $packageDir

	phpRedisVersion='phpredis-2.2.7'
	phpRedisPackage="${packageDir}/${phpRedisVersion}.tar.gz"

	[[ ! -f $phpRedisPackage ]] && curl -O http://www.hardyliu.me/packages/tar/php/${phpRedisVersion}.tar.gz
	tar zxf $phpRedisPackage || exit 4
	cd ${phpRedisVersion}
	phpize
	./configure --enable-reids-igbinary
	make && make install 

	if [[ $? -eq 0 ]]; then
		echo "extension=redis.so" > ${phpConfDir}/php.d/redis.ini
	fi

	systemctl restart php-fpm.service
}

check_environment
check_dependency
install_php
do_configuration
add_opcache
install_php_pecl_redis
