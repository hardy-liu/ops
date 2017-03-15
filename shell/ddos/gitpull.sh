#!/usr/bin/bash
# Function: git pull拉取代码
# Date: 2016-05-31

codeDir="/data/www/$1"											#代码目录
logFile="/data/log/$(basename $0 | cut -d "." -f1)_${1}.log"	#日志文件路径
ifRun=$(ps aux | grep -w "$0 $1" | wc -l)						#当前此脚本是否在运行
logSize=$(du -b $logFile | awk '{print $1}')					#当前日志文件的大小
logMaxSize=$(echo $[10*1024*1024])								#日志最大为10MB
allowedArgs=('ddos' 'ddos_agent' 'ddos_agent_pan' 'ddos_agent_v2' 'ddos_front_v2' 'ddos_pan')	#允许传递的参数

[[ ! -d $codeDir ]] && echo "$codeDir is not exists. exiting" && exit 1

#如果传递的不是指定的参数就退出
if ! echo "${allowedArgs[*]}" | grep -w "$1" &> /dev/null; then
	echo "invalid args."
	exit 2
fi

#创建日志文件保存目录
[[ ! -d $(dirname $logFile) ]] && mkdir -p $(dirname $logFile)

#如果gitpull程序已经在跑就终止上一次进程
function check_running {
	if [[ $ifRun -gt 3 ]]; then
		kill $(ps aux | grep -w "$0 $1" | awk '{print $2}' | head -1) && \
		echo -e "$(date "+%F %T") $0 is running. kill it." >> $logFile
	fi
}

#拉代码
function pull {
	cd $codeDir
	git pull &>> $logFile 
	echo -e "$(date "+%F %T")\n" >> $logFile
}

#清理日志
function purge_log {
	[[ $logSize -gt $logMaxSize ]] && echo -n "" > $logFile
}

#修改dns接口的域名ID为wydefcc.com
dnsClassFile="${codeDir}/php/prop/dns.class.php"		#dns类源文件
dnsClassBkFile="${codeDir}/php/prop/dns.class.php.bk"	#dns类备份文件
productDomainID='16139012'								#生产用的2ddos.com域名的域名ID

function alter_domain {
	if grep -w "${productDomainID}" ${dnsClassFile} &> /dev/null; then
		cp $dnsClassFile $dnsClassBkFile && \
		echo -e "$(date "+%F %T") copy $dnsClassFile to $dnsClassBkFile done." >> $logFile	
		sed -i "s/16139012/1520579/" $dnsClassFile && \
		echo -e "$(date "+%F %T") change domain id from $productDomainID to 1520579 done.\n" >> $logFile
	fi
}

check_running
pull
alter_domain
purge_log