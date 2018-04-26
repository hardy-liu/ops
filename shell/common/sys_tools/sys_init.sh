#!/bin/bash
# Author: liudian
# Date: 20160222
# Function: 系统初始化，做一些常用配置, 安装常用软件

devPackages=(pcre-devel openssl-devel)
commonPackages=(screen net-tools sysstat vim-enhanced git telnet bind-utils supervisor psmisc lrzsz crudini mailx mlocate expect dstat nload nethogs nfs-utils chrony bash-completion ipset whois) 

function install_packages() {
    local packages=($1)
    local i=''
    for i in ${packages[*]}; do
        if ! rpm -qi $i &> /dev/null; then
            yum install -y $i
        fi
    done
}

function change_hostname() {
    local hostname=''
    read -p "hostname: " hostname
    echo "$hostname" > /etc/hostname
    echo "127.0.0.1 $hostname" >> /etc/hosts
    hostname $hostname
}

function check_epel() {
    if ! yum repolist | grep "epel" &> /dev/null; then
        yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    fi
}

function install_dev_packages() {
    install_packages "${devPackages[*]}" \
    && yum groupinstall -y --skip-broken "Compatibility Libraries" "Development Tools"
}

function install_toolkit() {
    install_packages "${commonPackages[*]}"
}

function configure_vim() {
    cat >> /etc/vimrc << EOF
set noexpandtab
set sw=4
set tabstop=4
set softtabstop=4
EOF
}

function change_default_firewall() {
    yum -y install iptables-services
    systemctl stop firewalld
    systemctl disable firewalld
    systemctl start iptables
    systemctl enable iptables
    iptables -I INPUT -p tcp -m multiport --dport=80,443 -m comment --comment "Web Rules" -j ACCEPT
    iptables-save > /etc/sysconfig/iptables
}

function disable_selinux() {
    sed -i 's/^SELINUX=.*$/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
}

function add_history_timestamp() {
    if [[ -d /etc/profile.d ]]; then
        if [[ ! -f /etc/profile.d/history.sh ]]; then
            echo 'export HISTTIMEFORMAT="%F %T $(whoami) "' > /etc/profile.d/history.sh
            echo 'export HISTSIZE=2000' >> /etc/profile.d/history.sh
        fi
    else
        echo 'export HISTTIMEFORMAT="%F %T $(whoami) "' >> /etc/profile
    fi
}

function change_locale() {
    localectl set-locale LANG="en_US.UTF-8"
}

function add_ntp() {
    timedatectl set-timezone Asia/Shanghai
    systemctl enable chronyd
    systemctl start chronyd
}

function do_web_optimize() {
    curl -s https://raw.githubusercontent.com/hardy-liu/ops/master/shell/common/sys_tools/web_optimization.sh | bash - >> /dev/null \
    && echo "optimize ulimit and kernel success..."
}

echo "changing hostname..." \
&& change_hostname \
&& echo "checking epel..." \
&& check_epel >> /dev/null \
&& echo "installing dev packages..." \
&& install_dev_packages >> /dev/null \
&& echo "installing tollkit..." \
&& install_toolkit >> /dev/null \
&& echo "configuring vim..." \
&& configure_vim >> /dev/null \
&& echo "changing default firewall..." \
&& change_default_firewall >> /dev/null \
&& echo "disabling selinue..." \
&& disable_selinux >> /dev/null \
&& echo "adding history timestamp..." \
&& add_history_timestamp >> /dev/null \
&& echo "changing locale..." \
&& change_locale >> /dev/null \
&& echo "adding ntp..." \
&& add_ntp >> /dev/null \
&& echo "doing web optimization..." \
&& do_web_optimize
