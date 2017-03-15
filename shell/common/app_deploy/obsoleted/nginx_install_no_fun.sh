#!/usr/bin/env bash
# Function: install nginx from source
# Date: 2016-05-24
# Prerequisite: none
# Author: Hardy

packageDir='/data/packages/nginx'						#软件tar包存放目录
nginxVersion='nginx-1.9.7'								#nginx版本号
installPrefix='/opt'									#软件安装目录
nginxConfPath="${installPrefix}/etc/nginx/nginx.conf"	#nginx配置文件存放路径
cpuNum=$(grep -c "processor" /proc/cpuinfo)				#cpu核数，编译并行数量
runUser='nginx'											#nginx进程执行用户
logFile='/tmp/nginx_install.log'						#日志文件输出
dependPackages=(pcre-devel openssl-devel lua-json lua-devel lua-socket)

#下载安装包
[[ ! -d $packageDir ]] && mkdir -p $packageDir
: '
curl -O http://www.hardyliu.me/packages/tar/nginx/${nginxVersion}.tar.gz &
curl -O http://www.hardyliu.me/packages/tar/nginx/LuaJIT-2.0.4.tar.gz &
curl -O http://www.hardyliu.me/packages/tar/nginx/drizzle-nginx-module-0.1.9.tar.gz  &
curl -O http://www.hardyliu.me/packages/tar/nginx/drizzle7-2011.07.21.tar.gz &
curl -O http://www.hardyliu.me/packages/tar/nginx/echo-nginx-module-0.58.tar.gz &
curl -O http://www.hardyliu.me/packages/tar/nginx/lua-nginx-module-0.9.19.tar.gz &
curl -O http://www.hardyliu.me/packages/tar/nginx/lua-redis-parser-0.12.tar.gz &
curl -O http://www.hardyliu.me/packages/tar/nginx/nginx-module-vts-0.1.8.tar.gz &
curl -O http://www.hardyliu.me/packages/tar/nginx/ngx_cache_purge-2.3.tar.gz &
curl -O http://www.hardyliu.me/packages/tar/nginx/ngx_devel_kit-0.2.19.tar.gz &
curl -O http://www.hardyliu.me/packages/tar/nginx/rds-json-nginx-module-0.14.tar.gz &
curl -O http://www.hardyliu.me/packages/tar/nginx/redis-lua-2.0.4.tar.gz &
curl -O http://www.hardyliu.me/packages/tar/nginx/redis2-nginx-module-0.12.tar.gz &
curl -O http://www.hardyliu.me/packages/tar/nginx/set-misc-nginx-module-0.29.tar.gz &
wait
'

#安装依赖包
yum groupinstall -y --skip-broken "Compatibility Libraries" "Development Tools"
for i in ${dependPackages[*]}; do
	yum install -y $i
done

#解压所有压缩包
cd $packageDir
ls | grep "\.tar\.gz" | xargs -i tar zxf {}

#安装LuaJIT
cd ${packageDir}/LuaJIT-2.0.4
make -j ${cpuNum} && make install
[[ ! $? -eq 0 ]] && exit 1

#安装drizzle7（for drizzle-nginx-module）
cd ${packageDir}/drizzle7-2011.07.21
./configure --without-server
make libdrizzle-1.0
make install-libdrizzle-1.0
[[ ! $? -eq 0 ]] && exit 2

#安装nginx
cd ${packageDir}/${nginxVersion}
[[ ! -d $(dirname ${nginxConfPath}) ]] && mkdir $(dirname ${nginxConfPath}) 
export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.0
./configure \
	--prefix=${installPrefix}/${nginxVersion} \
	--conf-path=${nginxConfPath} \
	--error-log-path=/var/log/nginx/error.log \
	--http-log-path=/var/log/nginx/access.log \
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
	--add-module=../lua-nginx-module-0.9.19 \
	--add-module=../ngx_devel_kit-0.2.19 \
	--add-module=../redis2-nginx-module-0.12 \
	--add-module=../drizzle-nginx-module-0.1.9 \
	--add-module=../rds-json-nginx-module-0.14 \
	--add-module=../echo-nginx-module-0.58 \
	--add-module=../set-misc-nginx-module-0.29 \
	--add-module=../nginx-module-vts-0.1.8 \
	--add-module=../ngx_cache_purge-2.3
make -j ${cpuNum} && make install
[[ ! $? -eq 0 ]] && exit 3

#创建nginx执行用户
if ! id nginx &> /dev/null; then
	useradd -r -s /sbin/nologin $fpmUser
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

#启动nginx服务
systemctl daemon-reload
systemctl enable nginx.service
systemctl start nginx.service

#安装redis-lua
cd ${packageDir}/lua-redis-parser-0.12
export LUA_INCLUDE_DIR=/usr/local/include/luajit-2.0
gmake CC=gcc || exit 1
gmake install CC=gcc || exit 1

cp ${packageDir}/redis-lua-2.0.4/src/redis.lua /usr/share/lua/5.1/
