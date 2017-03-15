#!/bin/bash
logFile='/tmp/zabbix.log'
phpPackages=(php php-gd php-xmlrpc php-pecl-redis php-pear php-common php-pdo php-process php-mbstring php-cli php-mysql php-xml php-ldap php-pecl-igbinary php-fpm php-bcmath)
dbUser='root'
dbPass=''
dbPackages=(mariadb mariadb-server)
zabbixReleaseRPM='http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm'
zabbixReleaseNo='3.0.1'
zabbixServerPackages=(zabbix-server-mysql zabbix-web-mysql zabbix-agent)
nginxVhostFile='/usr/local/nginx/conf/vhosts/zabbix.test.com.conf'
nginxUser='nginx'	#nginx进程的执行用户

write_log() {
#    echo "$(date "+%F %T") $1" >> $logFile
    echo "$(date "+%F %T") $1" | tee -a $logFile
}

install_packages() {
	local a=($1)
	local i=''
	for i in ${a[*]}; do
		if ! rpm -qi $i &> /dev/null; then
			yum install -y $i &> /dev/null && write_log "install $i done." || \
			write_log "install $i failed."
		else 
			write_log "$i already installed, nothing to do."
		fi
	done
}

#安装NTP服务器/客户端工具
if ! rpm -qi chrony &> /dev/null; then
	yum -y install chrony &> /dev/null
    write_log "install and configure chrony done."
else
    write_log "chrony already installed, nothing to do."
fi
systemctl start chronyd &> /dev/null
systemctl enable chronyd &> /dev/null
#NTP服务器还要配置allow网段允许同步的网段

#安装php扩展，并配置php.ini配置文件
install_packages "${phpPackages[*]}"
[[ ! -f /etc/php.ini.bk ]] && cp /etc/php.ini /etc/php.ini.bk
yum instlal -y crudini && write_log "install crudini done."
crudini --set --existing /etc/php.ini PHP max_execution_time 300
crudini --set --existing /etc/php.ini PHP memory_limit 128M
crudini --set --existing /etc/php.ini PHP post_max_size 16M
crudini --set --existing /etc/php.ini PHP upload_max_filesize 2M
crudini --set --existing /etc/php.ini PHP max_input_time 300
crudini --set /etc/php.ini PHP always_populate_raw_post_data -1
crudini --set /etc/php.ini Date date.timezone Asia/Shanghai
write_log "install php and configure php.ini done."

#安装mysql数据库服务器，并创建zabbix数据库
install_packages "${dbPackages[*]}"
systemctl enable mariadb
systemctl start mariadb
mysql -u${dbUser} --password=${dbPass} -e "create database if not exists zabbix default charset utf8;" && \
write_log "create database zabbix done."

#创建zabbix@localhost用户，并授权其访问zabbix数据库
mysql -uroot --password=${dbPass} -e "grant all privileges on zabbix.* to 'zabbix'@'localhost' identified by 'zabbix';" && \
write_log "grant privileges to zabbix@localhost done."

#安装zabbix-server的相关rpm包
if ! rpm -qi zabbix-release &> /dev/null; then
	rpm -ivh $zabbixReleaseRPM &> /dev/null && \
	write_log "install zabbix-release done."
else 
	write_log "zabbix-release repo already installed, nothing to do"
fi
install_packages "${zabbixServerPackages[*]}"

#初始化zabbix数据库
cd /usr/share/doc/zabbix-server-mysql-${zabbixReleaseNo}
if [[ ! $(mysql -uroot --password= -e "show tables from zabbix;" | wc -l) -gt 0 ]];then
	zcat create.sql.gz | mysql -u${dbUser} --password=${dbPass} zabbix && \
	write_log "initialize zabbix db done."
else
	write_log "zabbix db already initialized, nothing to do."
fi

#编辑zabix_server配置文件，并启动服务
crudini --set /etc/zabbix/zabbix_server.conf '' DBHost localhost
crudini --set /etc/zabbix/zabbix_server.conf '' DBName zabbix
crudini --set /etc/zabbix/zabbix_server.conf '' DBUser zabbix
crudini --set /etc/zabbix/zabbix_server.conf '' DBPassword zabbix
#systemctl enable zabbix-server && systemctl start zabbix-server
#与RHEL7的gnults-3.3.8-12.el7包有兼容问题，无法systemd启动
if [[ $(cat /etc/rc.local | grep "zabbix_server" | wc -l) -eq 0 ]]; then
	echo "/usr/sbin/zabbix_server &" >> /etc/rc.local
	chmod +x /etc/rc.d/rc.local
fi
systemctl enable zabbix-agent &> /dev/null
systemctl start zabbix-agent && write_log "start zabbix-agent done."
/usr/sbin/zabbix_server

#生成nginx配置文件
if [[ ! $nginxVhostFile == '' ]]; then
	cat > $nginxVhostFile << EOF
server {
    listen 80;
    server_name zabbix.test.com;
    access_log /data/log/nginx/zabbix.log main;
	error_log /data/log/nginx/zabbix_error.log;
    root /data/www/zabbix;
    index index.html index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ ^/(conf|app|include|local) {
        return 404;
    }

    location ~ \.php$ {
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        try_files   \$uri =404;
        include        fastcgi.conf;
    }
}
EOF
	write_log "generate nginx vhost configuration done."
fi

#复制zabbix网页代码到/data/www下
cp -a /usr/share/zabbix/ /data/www/zabbix
chown -R nginx.nginx /data/www/zabbix

#更改配置文件权限为nginx用户
chown -R nginx.nginx  /etc/zabbix/web #默认是apache用户

#重载nginx配置文件
nginx -sreload
