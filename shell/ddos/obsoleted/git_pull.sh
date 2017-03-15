#!/bin/bash
#进入/data/www/fanghubao/目录啦coding上的代码

ifRun=$(ps aux | grep "git_pull\.sh" | wc -l)
[[ $ifRun -gt 2 ]] && exit 10 #如果进程在运行就退出
logFile=/data/log/git_pull.log
dnsClassDir="/data/www/fanghubao/php/prop"
dnsClassFile=${dnsClassDir}/dns.class.php
dnsClassBkFile=${dnsClassDir}/dns.class.php.bk

#拉代码
cd /data/www/fanghubao
if [[ -f $dnsClassBkFile ]];then
	mv -f $dnsClassBkFile $dnsClassFile
	git pull &>> $logFile
	echo "$(date +%F_%T)" >> $logFile
	echo "" >> $logFile
else
	git pull &>> $logFile
    echo "$(date +%F_%T)" >> $logFile
    echo "" >> $logFile
fi

#备份dns类文件，并修改测试环境的dns类的域名IP
cp $dnsClassFile $dnsClassBkFile
#sed -i "s/16139047/1520578/" $dnsClassFile  #将域名更改为wydefcc.com
sed -i "s/1520579/1520578/" $dnsClassFile  #将域名更改为wydefcc.com
