#!/bin/bash
#进入/data/www/ddos_v1.0.0/目录pull coding上的代码

ifRun=$(ps aux | grep "git_pull\.sh" | wc -l)
[[ $ifRun -gt 2 ]] && exit 10 #如果进程在运行就退出
logFile=/data/log/git_pull_v1.log
codeDir=/data/www/ddos_v1.0.0
dnsClassDir="/data/www/ddos_v1.0.0/php/prop"
dnsClassFile=${dnsClassDir}/dns.class.php
dnsClassBkFile=${dnsClassDir}/dns.class.php.bk

#拉代码
cd $codeDir
if [[ -f $dnsClassBkFile ]];then
	mv -f $dnsClassBkFile $dnsClassFile
fi

git pull &>> $logFile
echo -e "$(date +%F_%T)\n" >> $logFile

#备份dns类文件，并修改测试环境的dns类的域名IP
cp $dnsClassFile $dnsClassBkFile
#sed -i "s/16139047/1520578/" $dnsClassFile  #将域名更改为wydefcc.com
sed -i "s/16139012/1520578/" $dnsClassFile  #将域名更改为wydefcc.com
