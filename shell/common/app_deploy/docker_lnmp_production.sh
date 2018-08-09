#!/bin/bash
# Author: liudian
# Date: 20180426
# Function: 部署docker lnmp环境

dockerRegistry='hardyliu'
mysqlImage='mymysql:5.7.22'
phpImage='myphp-fpm:7.2.4'
nginxImage='mynginx:1.12.2'
redisImage='myredis:4.0.9'
dockerDataDir='/data/docker'
hypervisorIp=''		#docker宿主机ip, 即本机ip(非lo)
composeTemplate="${dockerDataDir}/docker-compose.yml"	#docker-compose
#dockerMysqlUid=''	#用户id
#dockerRedisUid=''
dockerWwwUid=''

#读取本机ip（手动输入）
function read_host_ip() {
	read -p "hypervisor ip: " hypervisorIp
}

#安装docker包
function install_docker() {
	#安装docker-ce依赖包
	[[ $(rpm -qa | grep docker-ce |wc -l) -lt 1 ]] && yum install -y yum-utils device-mapper-persistent-data lvm2 \
	&& yum install -y http://www.hardyliu.me/packages/rpm/docker/docker-ce-18.03.1.ce-1.el7.centos.x86_64.rpm
	[[ ! -d /etc/docker ]] && mkdir /etc/docker
	cat > /etc/docker/daemon.json << EOF 
{
  "registry-mirrors" : [
    "https://registry.docker-cn.com"
  ],
  "insecure-registries" : [
    "${dockerRegistry}"
  ],
  "dns" : [
    "8.8.8.8",
    "8.8.4.4"
  ]
}
EOF
}

function install_docker_composer() {
	local dockerComposeLocation='/usr/local/bin/docker-compose'
	if [[ ! -f $dockerComposeLocation ]]; then
		curl -s -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o $dockerComposeLocation
		chmod +x $dockerComposeLocation
		curl -s -L https://raw.githubusercontent.com/docker/compose/1.21.0/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose
	else
		echo 'docker-compose already exists. skip this step...'
	fi
}

#准备工作，创建目录等
function do_preparation() {
	if [[ -d $dockerDataDir ]]; then
		echo '![ERROR] docker数据映射目录已存在，退出...' >> /dev/stderr &&  exit 1 
	else 
		mkdir -p ${dockerDataDir}/{mysql,nginx,php,redis} \
		&& mkdir -p ${dockerDataDir}/mysql/{data,log} \
		&& mkdir -p ${dockerDataDir}/nginx/{conf,log,ssl} \
		&& mkdir -p ${dockerDataDir}/nginx/conf/{conf.d,extra} \
		&& mkdir -p ${dockerDataDir}/php/{log,session} \
		&& mkdir -p ${dockerDataDir}/redis/data \
		#添加php-fpm模版文件
		cat > ${dockerDataDir}/nginx/conf/extra/php-fpm.template << EOF
try_files       \${DOLLAR}uri =404;
fastcgi_pass    \${FASTCGI_HOST}:\${FASTCGI_PORT};
fastcgi_index   index.php;
fastcgi_param   SCRIPT_FILENAME    \${DOLLAR}document_root\${DOLLAR}fastcgi_script_name;
include         /etc/nginx/fastcgi_params;
EOF
	fi	
}

#下载docker镜像到本地
function fetch_docker_image() {
	systemctl start docker \
	&& systemctl enable docker \
	&& docker pull ${dockerRegistry}/${mysqlImage} \
	&& docker pull ${dockerRegistry}/${phpImage} \
	&& docker pull ${dockerRegistry}/${nginxImage} \
	&& docker pull ${dockerRegistry}/${redisImage} 
}

#通过docker-compose模版生成可执行yaml文件
function generate_compose_yaml() {
	#创建用户, 获取其id, 修改文件夹权限
	useradd -u 10003 -s /sbin/nologin docker-www 
	chown -R docker-www:docker-www {/data/www,/data/docker/nginx,/data/docker/php}
	dockerWwwUid=$(id -u docker-www)
	useradd -u 10001 -s /sbin/nologin docker-mysql 
	chown -R docker-mysql:docker-mysql /data/docker/mysql
#	dockerMysqlUid=$(id -u docker-mysql)
	useradd -u 10002 -s /sbin/nologin docker-redis 
	chown -R docker-redis:docker-redis /data/docker/redis
#	dockerRedisUid=$(id -u docker-redis)

	#下载配置文件模版
	curl -s -o $composeTemplate https://raw.githubusercontent.com/hardy-liu/ops/master/docker/docker-compose/docker-compose-production.yml.template
	sed -i "s/{mysqlImage}/${dockerRegistry}\/${mysqlImage}/g" $composeTemplate
	sed -i "s/{phpImage}/${dockerRegistry}\/${phpImage}/g" $composeTemplate
	sed -i "s/{nginxImage}/${dockerRegistry}\/${nginxImage}/g" $composeTemplate
	sed -i "s/{redisImage}/${dockerRegistry}\/${redisImage}/g" $composeTemplate
	sed -i "s/{hypervisorIp}/${hypervisorIp}/g" $composeTemplate
#	sed -i "s/{dockerMysqlUid}/${dockerMysqlUid}/g" $composeTemplate
#	sed -i "s/{dockerRedisUid}/${dockerRedisUid}/g" $composeTemplate
	sed -i "s/{dockerWwwUid}/${dockerWwwUid}/g" $composeTemplate
}

#添加hosts解析
function add_hosts_resolve() {
    echo "172.28.0.11 my-docker-mysql" >> /etc/hosts
    echo "172.28.0.12 my-docker-redis" >> /etc/hosts
    echo "172.28.0.13 my-docker-php-fpm" >> /etc/hosts
    echo "172.28.0.14 my-docker-nginx" >> /etc/hosts
}

#启动环境
function strart_app() {
	#docker swarm init --advertise-addr=$hypervisorIp \
	#&& docker stack deploy -c $composeTemplate web
    #todo 如果mysql数据库目录没有文件，那么需要先init初始化
    #docker-compose -f $composeTemplate up -d
    echo "make sure mysql data dir is not empty, or you have to init mysql first."
}

read_host_ip \
&& echo 'installing docker...' \
&& install_docker >> /dev/null \
&& echo 'installing docker-compose...' \
&& install_docker_composer \
&& echo 'doing prepation...' \
&& do_preparation >> /dev/null \
&& echo 'fetching docker images...' \
&& fetch_docker_image \
&& echo 'generating compose yaml...' \
&& generate_compose_yaml >> /dev/null \
&& echo 'adding hosts resolve...' \
&& add_hosts_resolve >> /dev/null \
&& echo 'starring app...' \
&& strart_app
