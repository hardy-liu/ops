#!/bin/bash 

ifRun=$(ps aux | grep "$(basename $0)" | wc -l)
[[ $ifRun -gt 3 ]] && exit 10 #如果进程在运行就退出
logFile=/data/log/git_add_tag_v1.log_
codeDir=/data/www/ddos_v1.0.0
dnsClassDir="/data/www/ddos_v1.0.0/php/prop"
dnsClassFile=${dnsClassDir}/dns.class.php
dnsClassBkFile=${dnsClassDir}/dns.class.php.bk
tagName=$1

cd $codeDir

if [[ -f $dnsClassBkFile ]];then
    mv -f $dnsClassBkFile $dnsClassFile
fi

git push
git tag -a $tagName -m "bug fixed, $(date +%F)"
git push origin $tagName

#备份dns类文件，并修改测试环境的dns类的域名IP
cp $dnsClassFile $dnsClassBkFile
#sed -i "s/16139047/1520578/" $dnsClassFile  #将域名更改为wydefcc.com
sed -i "s/16139012/1520579/" $dnsClassFile  #将域名更改为wydefcc.com
