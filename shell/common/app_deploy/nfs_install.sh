#!/usr/bin/env bash
# Author: liudian
# Date: 2016-09-19
# Function: 安装并配置nfs

sharedDir=('/data/data')							#共享目录
allowedHost='10.1.1.0/24'							#允许连接的主机
sharedUser='nginx'									#客户端来宾账号映射为的用户
sharedArgs='rw,all_squash'							#共享参数

#安装nfs
if ! yum info nfs-utils &> /dev/null; then
	yum install nfs-utils
fi

#创建用户
if ! id nginx &> /dev/null; then
	groupadd -g 3000 nginx
	useradd -s /sbin/nologin -r -u 3000 -g 3000 nginx
fi

#配置文件
userID=$(id -u nginx)
[[ ! -f /etc/exports ]] && echo "/etc/exports not exists, exiting." && exit 1
for i in ${sharedDir[*]}; do
	echo "$i ${allowedHost}(${sharedArgs},anonuid=${userID},anongid=${userID})" > /etc/exports
	chown -R ${sharedUser}.${sharedUser} $i
done

#打开防火墙端口
iptables -I INPUT -p tcp --dport 2049 -m comment --comment "NFS TCP Port" -j ACCEPT
iptables -I INPUT -p udp --dport 2049 -m comment --comment "NFS UDP Port" -j ACCEPT
iptables-save > /etc/sysconfig/iptables

#启动
systemctl start rpcbind.service 
systemctl start nfs-server.service
systemctl enable rpcbind.service 
systemctl enable nfs-server.service
