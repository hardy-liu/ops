#!/bin/bash
#
logFile='/data/log/zabbix_agent.log'
NTPServer='14.17.69.175'
zabbixReleaseRPM='http://repo.zabbix.com/zabbix/3.0/rhel/7/x86_64/zabbix-release-3.0-1.el7.noarch.rpm'
zabbixReleaseNo='3.0.1'
zabbixServer='14.17.69.175'
zabbixHostname=${0%%_zabbix_agent.sh}	#脚本名称前面加上主机前缀

write_log() {
    echo "$(date "+%F %T") $1" >> $logFile
}

#安装NTP服务器/客户端工具
if ! rpm -qi chrony &> /dev/null; then
	yum -y install chrony &> /dev/null
	sed -i '/^server/d' /etc/chrony.conf
	echo "server $NTPServer iburst" >> /etc/chrony.conf	
	systemctl start chronyd
	systemctl enable chronyd
	write_log "install and configure chrony done."
else 
	write_log "chrony already installed, nothing to do."
fi

#安装zabbix-agent包
if ! rpm -qi zabbix-release &> /dev/null; then
	rpm -ivh $zabbixReleaseRPM && \
	write_log "install zabbix-release done."
else 
	write_log "zabbix-release repo already installed, nothing to do"
fi
yum install -y zabbix-agent && \
write_log "zabbix agent install done."

#编辑agent配置文件
yum install -y crudini && write_log "install crudini done." || exit 1
#被动连接模式服务器IP
crudini --set /etc/zabbix/zabbix_agentd.conf '' Server $zabbixServer
#主动模式的服务器IP
crudini --set /etc/zabbix/zabbix_agentd.conf '' ServerActive $zabbixServer
#此监控节点的Hostname，与DNS无关，需要与服务器端的主机名相匹配
crudini --set /etc/zabbix/zabbix_agentd.conf '' Hostname $zabbixHostname
#允许从服务器端执行远程命令
crudini --set /etc/zabbix/zabbix_agentd.conf '' EnableRemoteCommands 1
#允许自定义zabbix监控项
crudini --set /etc/zabbix/zabbix_agentd.conf '' UnsafeUserParameters 1
systemctl enable zabbix-agent &> /dev/null
systemctl start zabbix-agent &> /dev/null && \
write_log "start zabbix-agent done."

#更改客户端的防火墙设置，允许10050通过
