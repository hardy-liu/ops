#!/usr/bin/env bash
# Function: 获取广州offic的IP，并更新到back.ddos.com.conf配置文件中
# Data: 2016-05-16

saveIP='/tmp/gz_offic_ip.txt'
previousIP=$(cat back.ddos.com.conf | grep "allow" | grep -E -o "([[:digit:]]+\.){3}[[:digit:]]+")
currentIP=$(curl -s https://down.vqiu.cn/api/public_gz-wy_1959c91f8be3.txt)
backConf='/opt/etc/nginx/vhosts/back.ddos.com.conf'

if [[ $previousIP != $currentIP ]]; then
    curl -s https://down.vqiu.cn/api/public_gz-wy_1959c91f8be3.txt > $saveIP
    sed -i "s/.*allow.*/\t allow $currentIP;/" /opt/etc/nginx/vhosts/back.ddos.com.conf

    if nginx -t; then
        nginx -s reload && \
        echo "$(date "+%F %T") reload nginx done."
    fi
else
    echo "$(date "+%F %T") ip not change, nothing to update."
fi
