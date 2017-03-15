#!/bin/bash
#Date: 20160326
#Function: 配置单点登录，发送om-proxy的公钥到其他主机上
hostName=(om-db om-web om-bbs om-svn om-web_test om-forum om-beta om-download om-backup)
hostPort=(22 22 22 22 8400 22 22 8400 8899)
if [[ ! -f /root/.ssh/id_rsa.pub ]]; then
    ssh-keygen -f /root/.ssh/id_rsa -N ''

	for i in $(seq 0 $[${#hostName[*]}-1]); do
		ssh-copy-id -p ${hostPort[$i]} -i /root/.ssh/id_rsa.pub root@${hostName[$i]} && \
		echo "send pub key to ${hostName[$i]} done."
	done
fi
