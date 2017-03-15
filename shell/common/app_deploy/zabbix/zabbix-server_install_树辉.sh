#/bin/bash
# 文件名：zabbix-server_install.sh
# 功能: zabbix server 自动安装脚本

ROOT_UID=0						                    # root uid
E_NOTROOT=67					                    # 退出代码

USER=zabbix						                    # zabbix 运行用户

CPU_CORE=$(grep 'processor' /proc/cpuinfo|wc -l)	# CPU 核数

DB_TABLE=zabbix					                    # zabbix 数据库
DB_USER=zabbix					                    # zabbix 数据库用户
DB_PASS="WcbtERNTESC6FziKvqHG"			            # zabbix 数据库连接密码[不宜使用特殊符号]

ZBX_SER_VER="3.0.1"

# 仅 root 用户下运行
if [[ $UID != "0" ]]
then
    echo "Error: Please use root role to run me!"
    exit $E_NOTROOT
fi

# 创建 zabbix 用户
id -u $USER>/dev/null
if [[ $? -ne 0 ]]
then
	groupadd -g 2000 $USER
	useradd -g 2000 -u 2000 -M -s /sbin/nologin $USER
else
	echo "Zabbix user already exists,don't need to create"
fi

yum install httpd mod_ssl make gcc php-cli php php-gd \
php-ldap php-mbstring php-snmp php-xml php-bcmath \
libxml2-devel net-snmp-devel net-snmp-utils unixODBC-devel \
libssh2-devel glibc-static pcre-devel OpenIPMI-devel openssl-devel \
gnutls-devel openldap-devel curl-devel libcurl-devel php-mysqlnd -y

sed -i "s/#ServerName www.example.com:80/ServerName ${HOSTNAME}/" /etc/httpd/conf/httpd.conf
sed -i "s/User apache/User ${USER}/" /etc/httpd/conf/httpd.conf
sed -i "s/Group apache/Group ${USER}/" /etc/httpd/conf/httpd.conf

sed -i 's/.*date.timezone =.*/date.timezone = PRC/g' /etc/php.ini
sed -i 's/.*post_max_size =.*/post_max_size = 16M/g' /etc/php.ini
sed -i 's/.*max_execution_time =.*/max_execution_time = 300/g' /etc/php.ini
sed -i 's/.*max_input_time =.*/max_input_time = 300/g' /etc/php.ini
chown ${USER}.${USER} /var/lib/php/session -R

yum -y install mariadb-server mariadb mariadb-devel php-mysql
systemctl start mariadb
systemctl enable mariadb

# 创建数据库
/usr/bin/mysql -uroot -e "CREATE DATABASE IF NOT EXISTS $DB_TABLE default charset utf8 COLLATE utf8_general_ci;"
/usr/bin/mysql -uroot -e "GRANT ALL ON $DB_TABLE.* to $DB_USER@localhost identified by '"${DB_PASS}"';" 
/usr/bin/mysql -uroot -e "FLUSH PRIVILEGES"


wget -c http://down.vqiu.cn/package/tarball/zabbix/zabbix-${ZBX_SER_VER}.tar.gz
tar axvf zabbix-${ZBX_SER_VER}.tar.gz
cd zabbix-${ZBX_SER_VER}
./configure \
--prefix=/usr/local/zabbix \
--enable-server \
--enable-agent \
--enable-ipv6 \
--with-mysql \
--with-openssl \
--with-ldap \
--with-net-snmp \
--with-libcurl \
--with-libxml2 \
--with-ssh2 \
--with-openipmi
if [[ $CPU_CORE -eq 1 ]]
then
    make;make install
else	
    make -j$CPU_CORE;make install
fi

# 复制配制文件
mkdir -p /etc/zabbix
\cp -r ./conf/* /etc/zabbix/
chown -R $USER:$USER /etc/zabbix

# 复制源码到 DocumentRoot
\cp -r frontends/php/* /var/www/html
chown -R $USER:$USER /var/www/html/

# 导入数据
cd ./database/mysql
/usr/bin/mysql -uroot ${DB_TABLE} < schema.sql
/usr/bin/mysql -uroot ${DB_TABLE} < images.sql
/usr/bin/mysql -uroot ${DB_TABLE} < data.sql

# zabbix-server.conf 配置
sed -i "s:.*PidFile=.*:PidFile=/tmp/zabbix_server.pid:" /etc/zabbix/zabbix_server.conf
sed -i "s/.*DBSchema=.*/DBSchema=${DB_TABLE}/" /etc/zabbix/zabbix_server.conf
sed -i "s/.*DBPassword=.*/DBPassword=${DB_PASS}/" /etc/zabbix/zabbix_server.conf
sed -i "s:.*DBSocket=/tmp/mysql.sock:DBSocket=/var/lib/mysql/mysql.sock:" /etc/zabbix/zabbix_server.conf

# zabbix-agentd.conf 配置
sed -i "s/.*EnableRemoteCommands=.*/EnableRemoteCommands=1/" /etc/zabbix/zabbix_agentd.conf 

# 设置环境变量
echo "export PATH=\$PATH:/usr/local/zabbix/sbin:/usr/local/zabbix/bin" > /etc/profile.d/zabbix.sh


cat > /lib/systemd/system/zabbix-server.service << 'EOF'
[Unit]
Description=Zabbix Server
After=syslog.target
After=network.target

[Service]
Environment="CONFFILE=/etc/zabbix/zabbix_server.conf"
EnvironmentFile=-/etc/sysconfig/zabbix-server
Type=forking
Restart=always
PIDFile=/tmp/zabbix_server.pid
KillMode=process
ExecStart=/usr/local/zabbix/sbin/zabbix_server -c $CONFFILE

[Install]
WantedBy=multi-user.target
EOF

cat > /lib/systemd/system/zabbix-agent.service << 'EOF'
[Unit]
Description=Zabbix Agent
After=syslog.target
After=network.target

[Service]
Environment="CONFFILE=/etc/zabbix/zabbix_agentd.conf"
EnvironmentFile=-/etc/sysconfig/zabbix-agent
Type=forking
Restart=always
PIDFile=/tmp/zabbix_agentd.pid
KillMode=process
ExecStart=/usr/local/zabbix/sbin/zabbix_agentd -c $CONFFILE

[Install]
WantedBy=multi-user.target
EOF

systemctl enable httpd
systemctl start httpd
systemctl enable zabbix-server
systemctl start zabbix-server
systemctl enable zabbix-agent
systemctl start zabbix-agent
