#!/usr/bin/env bash
# Author: liudian
# Date: 2016-11-24
# Function: build nginx from source

packageDir='/data/packages/nginx'						#软件tar包存放目录
nginxVersion='nginx-1.10.3'								#nginx版本号
installPrefix='/opt'									#软件安装目录
luajitDir="${installPrefix}/luajit"						#luajit安装目录
pidLockDir="${installPrefix}/run"						#pid和lock保存的目录
nginxConfPath="${installPrefix}/etc/nginx/nginx.conf"	#nginx配置文件存放路径
nginxErrorLogDir='/data/log/nginx'						#nginx错误日志保存目录
nginxAccessLogDir='/data/log/nginx'						#nginx访问日志保存目录
nginxTempDir='/data/nginx'								#nginx的临时目录父目录
nginxCacheDir='/data/nginx/cache'						#nginx缓存目录
cpuNum=$(grep -c "processor" /proc/cpuinfo)				#cpu核数，编译并行数量
runUser='nginx'											#nginx进程执行用户
logFile='/tmp/nginx_install.log'						#此脚本的日志文件
dependPackages=(pcre-devel openssl-devel lua-json lua-devel lua-socket)

#创建安装时需要的文件夹
function make_dir {
	[[ ! -d $packageDir ]] && mkdir -p $packageDir
	[[ ! -d $(dirname ${nginxConfPath}) ]] && mkdir -p $(dirname ${nginxConfPath}) 
	[[ ! -d $luajitDir ]] && mkdir -p $luajitDir
	[[ ! -d $pidLockDir ]] && mkdir -p $pidLockDir
	[[ ! -d $nginxErrorLogDir ]] && mkdir -p $nginxErrorLogDir
	[[ ! -d $nginxAccessLogDir ]] && mkdir -p $nginxAccessLogDir
	[[ ! -d $nginxTempDir ]] && mkdir -p ${nginxTempDir}/{client_temp,proxy_temp,fastcgi_temp,uwsgi_temp,scgi_temp}
	[[ ! -d $nginxCacheDir ]] && mkdir -p $nginxCacheDir
}


#下载安装包
function download_packages {
	cd $packageDir
	curl -O http://www.hardyliu.me/packages/tar/nginx/${nginxVersion}.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/LuaJIT-2.0.4.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/echo-nginx-module-0.60.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/lua-nginx-module-0.10.8.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/lua-redis-parser-0.13.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/redis-lua-2.0.4.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/nginx-module-vts-0.1.14.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/ngx_cache_purge-2.3.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/rds-json-nginx-module-0.14.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/redis2-nginx-module-0.14.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/ngx_devel_kit-0.3.0.tar.gz &
	curl -O http://www.hardyliu.me/packages/tar/nginx/set-misc-nginx-module-0.31.tar.gz &
	wait

	[[ ! $? -eq 0 ]] && exit 1
}

#检查epel源是否安装
function check_epel {
	if [[ $(yum repolist | grep epel |wc -l) -eq 0 ]]; then
		yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
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
	make -j ${cpuNum} && make install PREFIX=$luajitDir
	[[ ! $? -eq 0 ]] && exit 2
}

#安装redis-lua
function install_redis_lua {
	cd ${packageDir}/lua-redis-parser-0.13
	export LUA_INCLUDE_DIR=${luajitDir}/include/luajit-2.0
	gmake CC=gcc || exit 5
	gmake install CC=gcc || exit 6

	cp ${packageDir}/redis-lua-2.0.4/src/redis.lua /usr/share/lua/5.1/
}

#安装nginx
function install_nginx {
	cd ${packageDir}/${nginxVersion}
	export LUAJIT_LIB=${luajitDir}/lib
	export LUAJIT_INC=${luajitDir}/include/luajit-2.0
	./configure \
		--prefix=${installPrefix}/nginx \
		--conf-path=${nginxConfPath} \
		--pid-path=${pidLockDir}/nginx.pid \
		--lock-path=${pidLockDir}/nginx.lock \
		--error-log-path=${nginxErrorLogDir}/error.log \
		--http-log-path=${nginxAccessLogDir}/access.log \
		--http-client-body-temp-path=${nginxTempDir}/client_temp \
		--http-proxy-temp-path=${nginxTempDir}/proxy_temp \
		--http-fastcgi-temp-path=${nginxTempDir}/fastcgi_temp \
		--http-uwsgi-temp-path=${nginxTempDir}/uwsgi_temp \
		--http-scgi-temp-path=${nginxTempDir}/scgi_temp \
		--user=nginx \
		--group=nginx \
		--with-threads \
		--with-file-aio \
		--with-http_ssl_module \
		--with-http_realip_module \
		--with-http_sub_module \
		--with-http_stub_status_module \
		--with-http_gzip_static_module \
		--with-http_gunzip_module \
		--with-http_flv_module \
		--with-http_secure_link_module \
		--with-pcre \
		--with-pcre-jit \
		--with-ld-opt="-Wl,-rpath,${luajitDir}/lib" \
		--add-module=../lua-nginx-module-0.10.8 \
		--add-module=../nginx-module-vts-0.1.14 \
		--add-module=../redis2-nginx-module-0.14 \
		--add-module=../rds-json-nginx-module-0.14 \
		--add-module=../echo-nginx-module-0.60 \
		--add-module=../ngx_devel_kit-0.3.0 \
		--add-module=../set-misc-nginx-module-0.31 \
		--add-module=../ngx_cache_purge-2.3
	make -j ${cpuNum} && make install
	[[ ! $? -eq 0 ]] && exit 4
}

#添加systemd service脚本
function add_service {
	#创建nginx执行用户
	if ! id nginx &> /dev/null; then
		useradd -r -s /sbin/nologin $runUser
	fi

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
PIDFile=${pidLockDir}/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running \`nginx -t\` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/usr/bin/rm -f ${pidLockDir}/nginx.pid
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
}

#更改配置文件
function do_configuration {
	cd $(dirname $nginxConfPath)
	mkdir vhosts
	curl -O http://www.hardyliu.me/conf/add_headers.conf &
	curl -O http://www.hardyliu.me/conf/default.conf &
	curl -O http://www.hardyliu.me/conf/gzip.conf &
	curl -O http://www.hardyliu.me/conf/nginx.conf &
	curl -O http://www.hardyliu.me/conf/proxy.conf &
	curl -O http://www.hardyliu.me/conf/ssl.conf &
	wait
}

#启动服务
function start_service {
	systemctl daemon-reload
	systemctl enable nginx.service
	systemctl start nginx.service
}

make_dir
download_packages
check_epel
check_dependency
unpack_packages
install_LuaJIT
install_redis_lua
install_nginx
add_service
do_configuration
start_service
