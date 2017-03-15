#!/bin/bash
# Author: liudian
# Date: 20161114
# Function: 复制羁绊网配置文件，生成非标端口
#domainName=(
#	'test.xcmh.cc'
#	'player.xcmh.cc'
#	'newplayer.dilidili.tv'
#	'player.dilidili.tv '
#)
domainName=(
#	'test.xcmh.cc'
    'player.xcmh.cc'
    'player.dilidili.tv'
    'newplayer.dilidili.tv'
)
port=60001

for i in ${domainName[*]}; do
	confs=$(find /data/uploads/cdn/ -name "*${i}_ssl.conf*")
	for j in $confs; do
		newConf=${j%.*}_${port}.conf
		hostFile=$(basename ${j%.*})
		echo $newConf
		cp $j $newConf
		sed -i "s/443/${port}/g" $newConf
		sed -i "s/upstream ${hostFile}/upstream ${hostFile}_${port}/g" $newConf
		sed -i "s/proxy_pass[[:space:]]\+https:\/\/${hostFile}/proxy_pass https:\/\/${hostFile}_${port}/g" $newConf
	done	
done
