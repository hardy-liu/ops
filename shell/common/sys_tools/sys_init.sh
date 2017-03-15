#!/bin/bash
# Author: liudian
# Date: 20160222
# Function: 系统初始化，做一些常用配置, 安装常用软件

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
    hostname $hostname
}

function check_epel() {
    if ! yum repolist | grep "epel" &> /dev/null; then
        yum -y install http://mirrors.yun-idc.com/epel/epel-release-latest-7.noarch.rpm
    fi
}

function install_dev_packages() {
    local devPackages=(pcre-devel openssl-devel)
    install_packages "${devPackages[*]}"
    yum groupinstall -y --skip-broken "Compatibility Libraries" "Development Tools"
}

function install_toolkit() {
    local commonPackages=(screen net-tools sysstat vim-enhanced git telnet bind-utils supervisor psmisc lrzsz crudini mailx mlocate expect dstat nload nethogs nfs-utils chrony bash-completion)
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

function change_local() {
    localectl set-locale LANG="en_US.UTF-8"
}

function add_ntp() {
    timedatectl set-timezone Asia/Shanghai
    systemctl enable chronyd
    systemctl start chronyd
}

function change_nofile() {
    read -p "Optimize Ulimit Nofile Setting?[y|n]: " ifChangeNofile
    [[ $ifChangeNofile != 'y' ]] && return
    local ulimitNofileConf='/etc/security/limits.d/10-nofile.conf'
    if [[ ! -f $ulimitNofileConf ]]; then
        echo '* - nofile 100000' > $ulimitNofileConf
        echo 'fs.file-max = 2000000' >> /etc/sysctl.d/99-sysctl.conf
    fi
}

change_hostname
check_epel
install_dev_packages
install_toolkit
configure_vim
change_default_firewall
disable_selinux
add_history_timestamp
change_local
add_ntp
#change_nofile