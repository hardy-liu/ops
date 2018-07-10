#!/bin/bash
# Author: liudian
# Date: 20101114
# Function: 优化内核参数

ulimitConf='/etc/security/limits.d/90-web-optimize.conf'
kernelConf='/etc/sysctl.d/90-web-optimize.conf'

function set_ulimit {
	if [[ -f $ulimitConf ]]; then
		echo "$ulimitConf exist. exiting"
		exit 1
	fi

	cat > $ulimitConf << EOF
#设置每个进程可以打开的文件总数
* soft nofile 1000000
* hard nofile 1000000
#设置每个用户可以打开的进程数
* soft nproc 10000
* hard nproc 20000
EOF
}

function set_kernel {
	if [[ -f $kernelConf ]]; then
		echo "$kernelConf exist. exiting"
		exit 1
	fi

	cat > $kernelConf << EOF
#keppalive保持连接的时长
net.ipv4.tcp_keepalive_time = 600

#syn包的最大队列长度
net.ipv4.tcp_max_syn_backlog = 3000

#开启SYN Cookies，当出现SYN等待队列溢出时，启用cookies来处理
net.ipv4.tcp_syncookies = 1

#发送synack(第二次握手的确认包)的尝试次数, 可以防止syn flood攻击
net.ipv4.tcp_synack_retries = 1

#发送syn包的失败的尝试次数
net.ipv4.tcp_syn_retries = 2

#允许将TIME-WAIT sockets重新用于新的TCP连接
net.ipv4.tcp_tw_reuse = 1

#启用timewait快速回收
net.ipv4.tcp_tw_recycle = 1

#系统允许的端口范围
net.ipv4.ip_local_port_range = 1024  65500

#系统所有进程总共可以打开的文件数量
fs.file-max = 1000000

#redis
#每一个端口最大的监听队列的长度
net.core.somaxconn = 65535
#允许内存的overcommit
vm.overcommit_memory = 1
EOF
	sysctl -p $kernelConf
}

set_ulimit
set_kernel
