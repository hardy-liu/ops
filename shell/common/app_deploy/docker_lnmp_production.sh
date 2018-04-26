#!/bin/bash
# Author: liudian
# Date: 20180426
# Function: 部署docker lnmp环境

dockerRegistry='ecs-hk.hardyliu.me:5000'
mysqlImage='mymysql:5.7.22'
phpImage='myphp-fpm:7.2.4'
nginxImage='mynginx:1.12.2'
redisImage='myredis:4.0.9'
dockerDataDir='/data/docker'
hypervisorIp=''		#docker宿主机ip, 即本机ip(非lo)
composeTemplate="${dockerDataDir}/docker-compose.yml"	#docker-compose

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

#准备工作，创建目录等
function do_preparation() {
	if [[ -d $dockerDataDir ]]; then
		echo 'docker数据映射目录已存在，退出...'; exit 1 
	else 
		mkdir -p ${dockerDataDir}/{mysql,nginx,php72,redis} \
		&& mkdir -p ${dockerDataDir}/mysql/{data,log} \
		&& mkdir -p ${dockerDataDir}/nginx/{conf,log,ssl} \
		&& mkdir -p ${dockerDataDir}/nginx/conf/{conf.d,extra} \
		&& mkdir -p ${dockerDataDir}/php72/{log,session} \
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
	echo 'pulling docker image...'
	docker pull ${dockerRegistry}/${mysqlImage} &
	docker pull ${dockerRegistry}/${phpImage} &
	docker pull ${dockerRegistry}/${nginxImage} &
	docker pull ${dockerRegistry}/${redisImage} &
	wait

	docker tag ${dockerRegistry}/${mysqlImage} $mysqlImage \
	&& docker tag ${dockerRegistry}/${phpImage} $phpImage \
	&& docker tag ${dockerRegistry}/${nginxImage} $nginxImage \
	&& docker tag ${dockerRegistry}/${redisImage} $redisImage
}

#通过docker-compose模版生成可执行yaml文件
function generate_compose_yaml() {
	curl -s -o $composeTemplate https://raw.githubusercontent.com/hardy-liu/ops/master/docker/docker-compose/docker-compose-production.yml.template
	sed -i "s/{mysqlImage}/${mysqlImage}/" $composeTemplate
	sed -i "s/{phpImage}/${phpImage}/" $composeTemplate
	sed -i "s/{nginxImage}/${nginxImage}/" $composeTemplate
	sed -i "s/{redisImage}/${redisImage}/" $composeTemplate
	sed -i "s/{hypervisorIp}/${hypervisorIp}/" $composeTemplate
}

#启动环境
function strart_app() {
	systemctl enable docker \
	&& systemctl start docker \
	&& docker swarm init --advertise-addr=$hypervisorIp \
	&& docker stack deploy -c $composeTemplate web
}

&& read_host_ip \
&& echo 'installing docker...' \
&& install_docker >> /dev/null \
&& echo 'doing prepation...' \
&& do_preparation >> /dev/null \
&& echo 'fetching docker images...' \
&& fetch_docker_image >> /dev/null \
&& echo 'generating compose yaml...' \
&& generate_compose_yaml >> /dev/null \
&& echo 'starring app...' \
&& strart_app
