#!/bin/bash
# Author: liudian
# Date: 2016-10-08
# Function: 安装ocserv openconnect vpn 软件

tmpDir='/tmp'
packages=(ocserv crudini)
certDir='/etc/ocserv/ssl'
confFile='/etc/ocserv/ocserv.conf'

function gather_variables {
	read -p "vpn network is: " network				#分配给vpn客户端的ip地址池 192.168.11.0/24
	read -p "network interface is: " netInterface	#公网网卡接口
	read -p "vpn username is: " vpnUser				#vpn用户的用户名和密码
	read -p "vpn password is: " vpnPass
}

#生成CA证书
function generate_CA_cert {
	cd $tmpDir
	certtool --generate-privkey --outfile ca-key.pem	#生成私钥
	cat > ca.tmpl << EOF
cn = "VPN CA" 
organization = "Ocserv Corp" 
serial = 1 
expiration_days = -1 
ca 
signing_key 
cert_signing_key 
crl_signing_key 
EOF
	certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem
}

#生成server证书
function generate_server_cert {
	cd $tmpDir
	certtool --generate-privkey --outfile server-key.pem
	cat > server.tmpl << EOF
cn = "VPN server" 
dns_name = "www.example.com" 
dns_name = "vpn1.example.com" 
#ip_address = "1.2.3.4" 
organization = "MyCompany" 
expiration_days = -1 
signing_key 
encryption_key #only if the generated key is an RSA one 
tls_www_server 
EOF
	certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem
}

function move_cert {
	cd $tmpDir
	mv ca-key.pem ${certDir}
	mv ca-cert.pem ${certDir}/ca.crt
	mv server-key.pem ${certDir}/server.key
	mv server-cert.pem ${certDir}/server.crt
}

function check_epel {
	if ! yum repolist | grep 'epel' &> /dev/null; then
		echo "no epel. exiting"; exit 1
	fi
}

function install_packages {
	local i
	for i in ${packages[*]}; do
		yum -y install $i
	done
}

function check_certDir {
	[[ ! -d $certDir ]] && mkdir -p $certDir
}

function modify_conf {
	[[ ! -f $confFile ]] && echo "no confFile. exiting" && exit 2
	[[ ! -f ${confFile}.default ]] && cp $confFile ${confFile}.default	#备份配置文件
	crudini --set $confFile '' auth '"plain[/etc/ocserv/pwd]"'	
	crudini --set $confFile '' server-cert '/etc/ocserv/ssl/server.crt'
	crudini --set $confFile '' server-key '/etc/ocserv/ssl/server.key'
	crudini --set $confFile '' ca-cert '/etc/ocserv/ssl/ca.crt'
	crudini --set $confFile '' ipv4-network $network	
	crudini --set $confFile '' route 'default'
}

function modify_firewall_rule {
	[[ $(sysctl -n net.ipv4.ip_forward) -eq 0 ]] && sysctl -w net.ipv4.ip_forward=1
	echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf	#启用包转发

	iptables -F FORWARD		#清空FORWARD链，默认此链中的默认规则为禁止所有转发
	iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
	iptables -t nat -I POSTROUTING -o $netInterface -j MASQUERADE
	iptables -I INPUT -p tcp --dport 443 -j ACCEPT
	iptables -I INPUT -p udp --dport 443 -j ACCEPT
	#iptables-save > /etc/sysconfig/iptables
}

function generate_pass {
	echo $vpnPass | ocpasswd -c /etc/ocserv/pwd $vpnUser	
}

function start_service {
	#ocserv -fd 1 -c path_to_conf	#测试ocserv服务启动是否正常
	systemctl start ocserv
	systemctl enable ocserv	
}

gather_variables
check_epel
check_certDir
install_packages
generate_CA_cert
generate_server_cert
move_cert
modify_conf
modify_firewall_rule
generate_pass
start_service
