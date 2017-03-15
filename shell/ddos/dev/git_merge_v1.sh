#!/bin/bash
#进入/data/www/ddos_v1.0.0/目录merge master分支的代码

ifRun=$(ps aux | grep "$(basename $0)" | wc -l)
[[ $ifRun -gt 3 ]] && exit 10 #如果进程在运行就退出
logFile=/data/log/git_merge_v1.log
codeDir=/data/www/ddos_v1.0.0
dnsClassDir="/data/www/ddos_v1.0.0/php/prop"
dnsClassFile=${dnsClassDir}/dns.class.php
dnsClassBkFile=${dnsClassDir}/dns.class.php.bk

#合并master代码到ddos_1.0.0分支上
cd $codeDir

if [[ -f $dnsClassBkFile ]];then
	mv -f $dnsClassBkFile $dnsClassFile
fi

git checkout master
git pull
git checkout ddos_1.0.0
git merge --no-ff master

#git pull &>> $logFile
#echo -e "$(date +%F_%T)\n" >> $logFile

#备份dns类文件，并修改测试环境的dns类的域名IP
cp $dnsClassFile $dnsClassBkFile
#sed -i "s/16139047/1520578/" $dnsClassFile  #将域名更改为wydefcc.com
sed -i "s/16139012/1520579/" $dnsClassFile  #将域名更改为wydefcc.com
