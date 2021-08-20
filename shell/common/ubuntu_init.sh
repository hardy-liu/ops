#!/bin/bash

#时区
timedatectl set-timezone Asia/Shanghai

#创建目录
mkdir -p /data/{www,docker}

#配置vim
cat >> /etc/vim/vimrc << EOF
set noexpandtab
set sw=4
set tabstop=4
set softtabstop=4
set nu
EOF

#设置locale
localectl set-locale en_US.UTF-8

#设置ulimit
cat > /etc/security/limits.conf << EOF
#设置每个进程可以打开的文件总数
* soft nofile 1000000
* hard nofile 1000000
#设置每个用户可以打开的进程数
* soft nproc 1000000 
* hard nproc 1000000
EOF

#kernel setting
kernelConf='/etc/sysctl.d/90-optimization.conf'
if [[ -f $kernelConf ]]; then
    echo "$kernelConf exist. exiting"
    exit 1
fi
cat > $kernelConf << EOF
#keppalive保持连接的时长
#net.ipv4.tcp_keepalive_time = 600

#syn包的最大队列长度
net.ipv4.tcp_max_syn_backlog = 3000

#开启SYN Cookies，当出现SYN等待队列溢出时，启用cookies来处理
net.ipv4.tcp_syncookies = 1

#发送synack(第二次握手的确认包)的尝试次数, 可以防止syn flood攻击
net.ipv4.tcp_synack_retries = 1

#发送syn包的失败的尝试次数
net.ipv4.tcp_syn_retries = 2

#允许将TIME-WAIT sockets重新用于新的TCP连接
#net.ipv4.tcp_tw_reuse = 1

#启用timewait快速回收
#net.ipv4.tcp_tw_recycle = 1

#系统允许的端口范围
net.ipv4.ip_local_port_range = 1024  65500

#系统所有进程总共可以打开的文件数量
fs.file-max = 9223372036854775807

#redis
#每一个端口最大的监听队列的长度
net.core.somaxconn = 65535
#允许内存的overcommit
vm.overcommit_memory = 1
EOF
sysctl -p $kernelConf

#安装软件包
apt-get install -y lrzsz mysql-client redis-tools
