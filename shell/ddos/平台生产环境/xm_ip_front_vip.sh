#!/bin/bash
# Author: liudian
# Date: 20161121
# Funtion: 添加/删除厦门高防ip节点vip

ipPrefixDx=120.41.38    #电信vip 120.41.38.128/25
ipPrefixYd=183.252.53   #移动vip 183.252.53.128/28

#检查脚本运行者的权限
function check_pri {
    if [[ $UID -ne 0 ]]; then
        echo "Please use root role to run this script."
        exit 1
    fi 
}

#检查参数并执行
function check_args {
    local line=('dx' 'yd')
    local ops=('add' 'del') 
    if ! echo "${ops[*]}" | grep -w "$2" &> /dev/null; then
        echo "invalid \$2 args.[add|del]"
        exit 2
    fi 
    case $1 in
        dx)
            dx_vip $2
            ;;
        yd)
            yd_vip $2
            ;;
        *)
            echo "invalid \$1 args.[dx|yd]"
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

#添加/移除移动vip到lo接口
function yd_vip {
    local i
    for i in {128..143}; do
        ip addr $1 ${ipPrefixYd}.${i}/32 dev lo
        echo "$1 lo:${ipPrefixYd}.${i} done."
    done
}

check_args $1 $2
