#!/usr/bin/env bash
# Author: liudian
# Date: 2016-05-24
# Function: install nginx from source

packageDir='/data/packages/nginx'						#软件tar包存放目录
nginxVersion='nginx-1.10.1'								#nginx版本号
installPrefix='/opt'									#软件安装目录
nginxConfPath="${installPrefix}/etc/nginx/nginx.conf"	#nginx配置文件存放路径
nginxLogPath='/data/log/nginx'							#nginx日志保存目录
cpuNum=$(grep -c "processor" /proc/cpuinfo)				#cpu核数，编译并行数量
runUser='nginx'											#nginx进程执行用户
logFile='/tmp/nginx_install.log'						#日志文件输出
dependPackages=(pcre-devel openssl-devel lua-json lua-devel lua-socket)

[[ ! -d $packageDir ]] && mkdir -p $packageDir
[[ ! -d $(dirname ${nginxConfPath}) ]] && mkdir -p $(dirname ${nginxConfPath}) 
[[ ! -d $nginxLogPath ]] && mkdir -p $nginxLogPath

#下载安装包
function download_packages {
	cd $packageDir
	curl -O http://www.hardyliu.me/packages/tar/nginx/${nginxVersion}.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/LuaJIT-2.0.4.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/drizzle-nginx-module-0.1.9.tar.gz  &
	curl -O http://www.hardyliu.me/packages/tar/nginx/drizzle7-2011.07.21.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/echo-nginx-module-0.58.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/lua-nginx-module-0.10.6.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/lua-redis-parser-0.12.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/nginx-module-vts-0.1.8.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/ngx_cache_purge-2.3.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/ngx_devel_kit-0.2.19.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/rds-json-nginx-module-0.14.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/redis-lua-2.0.4.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/redis2-nginx-module-0.12.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/set-misc-nginx-module-0.29.tar.gz &
	wait

	[[ ! $? -eq 0 ]] && exit 1
}

#检查epel源是否安装
function check_epel {
	if [[ $(yum repolist | grep epel |wc -l) -eq 0 ]]; then
		yum -y install http://mirrors.yun-idc.com/epel/epel-release-latest-7.noarch.rpm
	fi
}

#安装依赖包
function check_dependency {
	yum groupinstall -y --skip-broken "Compatibility Libraries" "Development Tools"
	for i in ${dependPackages[*]}; do
		yum install -y $i
	done
}

#解压所有压缩包
function unpack_packages {
	cd $packageDir
	ls | grep -v "\.tar\.gz" | xargs -i rm -rf {} 
	ls | grep "\.tar\.gz" | xargs -i tar zxf {}
}

#安装LuaJIT
function install_LuaJIT {
	cd ${packageDir}/LuaJIT-2.0.4
	make -j ${cpuNum} && make install
	[[ ! $? -eq 0 ]] && exit 2
}

#安装drizzle7（for drizzle-nginx-module）
function install_drizzle7 { 
	cd ${packageDir}/drizzle7-2011.07.21
	./configure --without-server
	make libdrizzle-1.0
	make install-libdrizzle-1.0
	[[ ! $? -eq 0 ]] && exit 3
}

#安装nginx
function install_nginx {
	cd ${packageDir}/${nginxVersion}
	export LUAJIT_LIB=/usr/local/lib
	export LUAJIT_INC=/usr/local/include/luajit-2.0
	./configure \
		--prefix=${installPrefix}/${nginxVersion} \
		--conf-path=${nginxConfPath} \
		--error-log-path=${nginxLogPath}/error.log \
		--http-log-path=${nginxLogPath}/access.log \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/lock/nginx.lock \
		--user=nginx \
		--group=nginx \
		--with-http_ssl_module \
		--with-http_flv_module \
		--with-http_stub_status_module \
		--with-http_gzip_static_module \
		--with-file-aio \
		--with-pcre \
		--with-http_v2_module \
		--with-http_realip_module \
		--with-http_gunzip_module \
		--with-http_sub_module \
		--with-ld-opt="-Wl,-rpath,/usr/local/lib" \
		--add-module=../lua-nginx-module-0.10.6 \
		--add-module=../ngx_devel_kit-0.2.19 \
		--add-module=../redis2-nginx-module-0.12 \
		--add-module=../drizzle-nginx-module-0.1.9 \
		--add-module=../rds-json-nginx-module-0.14 \
		--add-module=../echo-nginx-module-0.58 \
		--add-module=../set-misc-nginx-module-0.29 \
		--add-module=../nginx-module-vts-0.1.8 \
		--add-module=../ngx_cache_purge-2.3
	make -j ${cpuNum} && make install
	[[ ! $? -eq 0 ]] && exit 4
}

#执行安装完成之后的配置
function do_configuration {
	#创建nginx执行用户
	if ! id nginx &> /dev/null; then
		useradd -r -s /sbin/nologin $runUser
	fi

	#建立软链接
	ln -sv ${installPrefix}/${nginxVersion} ${installPrefix}/nginx

	#添加nginx命令到环境变量
	echo "export PATH=\$PATH:${installPrefix}/nginx/sbin" > /etc/profile.d/nginx.sh

	#添加systemd service文件
	if [[ ! -f /usr/lib/systemd/system/nginx.service ]]; then
	cat > /usr/lib/systemd/system/nginx.service  << EOF
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running \`nginx -t\` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/usr/bin/rm -f /var/run/nginx.pid
ExecStartPre=${installPrefix}/nginx/sbin/nginx -t
ExecStart=${installPrefix}/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP \$MAINPID
KillMode=process
KillSignal=SIGQUIT
TimeoutStopSec=5
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
	fi

	systemctl daemon-reload
	systemctl enable nginx.service
	systemctl start nginx.service
}

#安装redis-lua
function install_redis_lua {
	cd ${packageDir}/lua-redis-parser-0.12
	export LUA_INCLUDE_DIR=/usr/local/include/luajit-2.0
	gmake CC=gcc || exit 5
	gmake install CC=gcc || exit 6

	cp ${packageDir}/redis-lua-2.0.4/src/redis.lua /usr/share/lua/5.1/
}

download_packages
check_epel
check_dependency
unpack_packages
install_LuaJIT
install_drizzle7
install_nginx
do_configuration
install_redis_lua
