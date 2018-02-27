#!/bin/bash
# Author: liudian
# Date: 2016-07-30
# Function: 自动安装shadowsocks

repoFile='/etc/yum.repos.d/shadowsocks.repo'			#shadowsocks的yum配置文件
shadowPackages=('libsodium13' 'shadowsocks-qt5' 'shadowsocks-libev')	#软件包
shadowConf='/etc/shadowsocks-libev/config.json'			#配置文件
ipAddr='0.0.0.0' 										#监听ip地址
pass='sh1nzII59D'										#shadowsocks连接的密码
listenPort='8388'										#监听的端口

#检查并安装epel源
function check_epel {
	ifEpel=$( yum repolist | grep epel |wc -l)
	[[ $ifEpel -eq 0 ]] && yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
}

#添加shadowsocks的repo配置文件
function add_repo {
	cat > $repoFile << EOF
[librehat-shadowsocks]
name=Copr repo for shadowsocks owned by librehat
baseurl=https://copr-be.cloud.fedoraproject.org/results/librehat/shadowsocks/epel-7-\$basearch/
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://copr-be.cloud.fedoraproject.org/results/librehat/shadowsocks/pubkey.gpg
enabled=1
enabled_metadata=1
EOF
}

#安装shadowsocks软件包
function install_shadow {
	for i in ${shadowPackages[*]}; do
		yum install -y $i
	done
}

#编辑shadowsockv服务器端配置文"
function edit_conf {
	cp $shadowConf $(dirname $shadowConf)/config.json.default
	cat > $shadowConf << EOF
{
    "server":"$ipAddr",
    "server_port":$listenPort,
    "local_port":1080,
    "password":"$pass",
    "timeout":60,
    "method":"aes-256-cfb"
}
EOF
}

#编辑service文件并启动服务
function edit_service {
	sed -i 's/Group=$GROUP/#Group=$GROUP/' /usr/lib/systemd/system/shadowsocks-libev.service
	systemctl daemon-reload
	systemctl restart shadowsocks-libev
	systemctl enable shadowsocks-libev
}

check_epel
add_repo
install_shadow
edit_conf
edit_service
#打开防火墙端口$listenPort
