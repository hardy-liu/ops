#!/bin/bash
# Data: 2016-01-07
# Usage: 将脚本和软件包放置在一起，并在此目录执行此脚本

#安装依赖包
yum install -y pcre-devel
yum groupinstall -y --skip-broken "Compatibility Libraries" "Development Tools"
yum install -y  openssl-devel
rootDir="$(pwd)/"

#安装LuaJIT
tar xf "LuaJIT-2.0.4.tar.gz"
cd ${rootDir}LuaJIT-2.0.4
make || exit 1
make install || exit 1

#安装drizzle7（for drizzle-nginx-module）
cd ${rootDir}
tar xf "drizzle7-2011.07.21.tar.gz"
cd ${rootDir}drizzle7-2011.07.21/
./configure --without-server
make libdrizzle-1.0
make install-libdrizzle-1.0

#安装nginx
cd ${rootDir}
tar xf "ngx_devel_kit-0.2.19.tar.gz"
tar xf "lua-nginx-module-0.9.19.tar.gz"
tar xf "redis2-nginx-module-0.12.tar.gz"
tar xf "echo-nginx-module-0.58.tar.gz"
tar xf "set-misc-nginx-module-0.29.tar.gz"
tar xf "nginx-module-vts-0.1.8.tar.gz"
tar xf "ngx_cache_purge-2.3.tar.gz"
tar xf "nginx-1.9.7.tar.gz"
tar xf "drizzle-nginx-module-0.1.9.tar.gz"
tar xf "rds-json-nginx-module-0.14.tar.gz"
cd ${rootDir}nginx-1.9.7
export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.0
./configure --prefix=/opt/nginx --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock --user=nginx --group=nginx --with-http_ssl_module --with-http_flv_module --with-http_stub_status_module --with-http_gzip_static_module --with-file-aio --with-pcre --with-http_v2_module --with-http_realip_module --with-http_gunzip_module --with-http_sub_module --with-ld-opt="-Wl,-rpath,/usr/local/lib" --add-module=../lua-nginx-module-0.9.19 --add-module=../ngx_devel_kit-0.2.19 --add-module=../redis2-nginx-module-0.12 --add-module=../drizzle-nginx-module-0.1.9 --add-module=../rds-json-nginx-module-0.14 --add-module=../echo-nginx-module-0.58 --add-module=../set-misc-nginx-module-0.29 --add-module=../nginx-module-vts-0.1.8 --add-module=../ngx_cache_purge-2.3 || exit 1
make || exit 1
make install || exit 1
#useradd -r nginx -s /sbin/nologin
echo "export PATH=$PATH:/usr/local/nginx/sbin" > /etc/profile.d/nginx.sh

#添加systemd service文件
if [[ ! -f /usr/lib/systemd/system/nginx.service ]]; then
cat >>/usr/lib/systemd/system/nginx.service  << EOF
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running `nginx -t` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/usr/bin/rm -f /var/run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
KillMode=process
KillSignal=SIGQUIT
TimeoutStopSec=5
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable nginx
fi

#安装redis-lua
cd ${rootDir}
tar xf "lua-redis-parser-0.12.tar.gz"
cd ${rootDir}lua-redis-parser-0.12
export LUA_INCLUDE_DIR=/usr/local/include/luajit-2.0
gmake CC=gcc || exit 1
gmake install CC=gcc || exit 1

yum install -y lua-json
yum install -y lua-devel
yum install -y lua-socket
cd ${rootDir}
tar xf "redis-lua-2.0.4.tar.gz"
cp redis-lua-2.0.4/src/redis.lua /usr/share/lua/5.1/ || exit 1
