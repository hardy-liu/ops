#!/bin/bash
# Author: liudian
# Date: 20161122
# Funtion: 添加/删除厦门高防CDN节点vip

ipPrefixDx=120.41.39    #电信vip 120.41.39.0/25
ipPrefixLt=36.248.217   #联通vip 36.248.217.144-255

#检查脚本运行者的权限
function check_pri {
    if [[ $UID -ne 0 ]]; then
        echo "Please use root role to run this script."
        exit 1
    fi 
}

#检查参数并执行
function check_args {
    local line=('dx' 'lt')
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
        *)
            echo "invalid \$1 args.[dx|lt]"
            exit 3
            ;;
    esac   
}

#添加/移除电信vip到lo接口
function dx_vip {
    local i
    for i in {0..127}; do
        ip addr $1 ${ipPrefixDx}.${i}/32 dev lo
        echo "$1 lo:${ipPrefixDx}.${i} done."
    done
}

#添加/移除联通vip到lo接口
function lt_vip {
    local i
    for i in {144..255}; do
        ip addr $1 ${ipPrefixLt}.${i}/32 dev lo
        echo "$1 lo:${ipPrefixLt}.${i} done."
    done
}

check_args $1 $2
