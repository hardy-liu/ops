#!/bin/bash
# Author: liudian
# Date: 20161124
# Funtion: 添加/删除厦门高防CDN测试节点vip

ipPrefixDx=120.41.38    #电信vip 120.41.38.128/25  128-255
ipPrefixLt=36.248.217   #联通vip 36.248.217.144/28 144-159
ipPrefixYd=183.252.53	#移动vip 183.252.53.128/28 128-143
line=('dx' 'lt' 'yd')

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
        dx)
            dx_vip $2
            ;;
        lt)
            lt_vip $2
            ;;
		yd)
			yd_vip $2
			;;
        *)
            echo "invalid \$1 args.[dx|lt|yd]"
            exit 3
            ;;
    esac   
}

#添加/移除电信vip到lo接口
function dx_vip {
    local i
    for i in {128..255}; do
        ip addr $1 ${ipPrefixDx}.${i}/32 dev lo
        echo "$1 lo:${ipPrefixDx}.${i} done."
    done
}

#添加/移除联通vip到lo接口
function lt_vip {
    local i
    for i in {144..159}; do
        ip addr $1 ${ipPrefixLt}.${i}/32 dev lo
        echo "$1 lo:${ipPrefixLt}.${i} done."
    done
}

#添加/移除移动vip到lo接口
function yd_vip {
    local i
    for i in {128..143}; do
        ip addr $1 ${ipPrefixYd}.${i}/32 dev lo
        echo "$1 lo:${ipPrefixYd}.${i} done."
    done
}

for i in ${line[*]}; do
	action $i $1
done
