#!/bin/bash
# Author: liudian
# Data: 2016-04-18
# Function: 自动安装gitlab（未完成）


logFile='/data/log/gitlab_installation.log'
postfixDomain='tuju.cn'	#the value of mydomain in postfix configuration file

[ ! -d $(dirname ${logFile}) ] && mkdir -p $(dirname ${logFile})

#Install and configure the necessary dependencies
yum install -y curl openssl-server
yum install -y crudini	#install .ini editor

#install and configure postfix
if ! rpm -qi postfix &> /dev/null; then
	yum install postfix
fi

[ ! -f /etc/postfix/main.cf.default ] && cp /etc/postfix/{main.cf,main.cf.default}
crudini --set main.cf '' myhostname $(hostname)
crudini --set main.cf '' mydomain $postfixDomain
crudini --set main.cf '' myorigin '$mydomain'
crudini --set main.cf '' mydestination '$myhostname, localhost.$mydomain, localhost, $mydomain'
crudini --set main.cf '' mynetworks '127.0.0.0/8'

systemctl enable postfix
systemctl restart postfix

#Add the GitLab package server and install the package
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.rpm.sh | bash
yum install gitlab-ce
#alternatively, we can download the package manually and install it instead of running the script
#curl -LJO https://packages.gitlab.com/gitlab/gitlab-ce/packages/el/7/gitlab-ce-XXX.rpm/download
#rpm -i gitlab-ce-XXX.rpm

#configure and start gitlab
gitlab-ctl reconfigure

#configure iptalbes allow http in