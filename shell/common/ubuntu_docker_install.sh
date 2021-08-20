#!/bin/bash

#install docker engine
cd /data/www/shell
curl -fsSL https://get.docker.com -o get-docker.sh
sh ./get-docker.sh

#install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

#download image
localIp=$(ip addr | grep ens | grep inet | awk '{print $2}' | awk -F'/' '{print $1}')
if [[ -z "$localIp" ]]; then
    echo "WARN: localIp empty"
    exit 1
fi
dockerDataDir='/data/docker'
dockerRegistry='hardyliu'
mysqlImage='mymysql:8.0.19'
phpImage='myphp-fpm:7.4.4'
nginxImage='mynginx:1.16.1'
redisImage='myredis:5.0.8'
composeTemplate="${dockerDataDir}/docker-compose.yml"   #docker-compose
#创建目录
mkdir -p $dockerDataDir
mkdir -p ${dockerDataDir}/{mysql,nginx,php,redis}
mkdir -p ${dockerDataDir}/mysql/{custom.conf.d,data,log}
mkdir -p ${dockerDataDir}/nginx/{conf,log,ssl}
mkdir -p ${dockerDataDir}/nginx/conf/{conf.d,extra}
mkdir -p ${dockerDataDir}/php/{log,session}
mkdir -p ${dockerDataDir}/redis/data
#添加mysql配置文件
curl -s -o ${dockerDataDir}/mysql/custom.conf.d/custom.cnf https://raw.githubusercontent.com/hardy-liu/ops/master/docker/mysql/8.0.19/custom.conf.d/custom.cnf
#添加php-fpm模版文件
cat > ${dockerDataDir}/nginx/conf/extra/php-fpm.template << EOF
try_files       \${DOLLAR}uri =404;
fastcgi_pass    \${FASTCGI_HOST}:\${FASTCGI_PORT};
fastcgi_index   index.php;
fastcgi_param   SCRIPT_FILENAME    \${DOLLAR}document_root\${DOLLAR}fastcgi_script_name;
include         /etc/nginx/fastcgi_params;
EOF
#下载镜像
docker pull ${dockerRegistry}/${mysqlImage}
docker pull ${dockerRegistry}/${phpImage}
docker pull ${dockerRegistry}/${nginxImage}
docker pull ${dockerRegistry}/${redisImage}
#配置用户
useradd -u 10003 -s /sbin/nologin docker-www
chown -R docker-www:docker-www {/data/www,/data/docker/nginx,/data/docker/php}
useradd -u 10001 -s /sbin/nologin docker-mysql
chown -R docker-mysql:docker-mysql /data/docker/mysql
useradd -u 10002 -s /sbin/nologin docker-redis
chown -R docker-redis:docker-redis /data/docker/redis
#下载配置文件模版
curl -s -o $composeTemplate https://raw.githubusercontent.com/hardy-liu/ops/master/docker/docker-compose/docker-compose-production.yml.template
sed -i "s/{mysqlImage}/${dockerRegistry}\/${mysqlImage}/g" $composeTemplate
sed -i "s/{phpImage}/${dockerRegistry}\/${phpImage}/g" $composeTemplate
sed -i "s/{nginxImage}/${dockerRegistry}\/${nginxImage}/g" $composeTemplate
sed -i "s/{redisImage}/${dockerRegistry}\/${redisImage}/g" $composeTemplate
sed -i "s/{hypervisorIp}/${localIp}/g" $composeTemplate
sed -i "s/{dockerWwwUid}/10003/g" $composeTemplate
#配置hosts
echo "172.28.0.11 my-docker-mysql" >> /etc/hosts
echo "172.28.0.12 my-docker-redis" >> /etc/hosts
echo "172.28.0.13 my-docker-php-fpm" >> /etc/hosts
echo "172.28.0.14 my-docker-nginx" >> /etc/hosts
#初始化mysql，启动容器
/usr/local/bin/docker-compose -f $composeTemplate run mysql mysqld --initialize
/usr/local/bin/docker-compose -f $composeTemplate up -d
#set mysql password
#docker-compose exec mysql mysql -uroot --skip-password -e"use mysql;CREATE USER 'root'@'172.28.%' IDENTIFIED BY 'pass';GRANT ALL ON *.* TO 'root'@'172.28.%' WITH GRANT OPTION;FLUSH PRIVILEGES"
