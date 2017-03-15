#!/bin/bash
# Author: liudian
# Date: 20161124
# Funtion: 添加/删除厦门高防CDN测试节点vip

ipPrefixPrivate=172.17.33    #内网ip 172.17.33.0/20 0-255
ifName='eno1'				 #配置内网ip的网卡
line=('private')

#检查脚本运行者的权限
function check_pri {
    if [[ $UID -ne 0 ]]; then
        echo "Please use root role to run this script."
        exit 1
    fi 
}

#检查参数并执行
function action {
    local ops=('add' 'del') 
    if ! echo "${ops[*]}" | grep -w "$2" &> /dev/null; then
        echo "invalid \$2 args.[add|del]"
        exit 2
    fi 
    case $1 in
		private)
			private_ip $2
			;;
        *)
            echo "invalid \$1 args.[private]"
            exit 3
            ;;
    esac   
}

#添加/移除内网ip
function private_ip {
    local i
    for i in {0..255}; do
        ip addr $1 ${ipPrefixPrivate}.${i}/20 dev $ifName
        echo "$1 $ifName:${ipPrefixPrivate}.${i} done."
    done
}

for i in ${line[*]}; do
	action $i $1
done
