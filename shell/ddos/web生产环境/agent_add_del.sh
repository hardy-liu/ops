#!/bin/bash
# Author: liudian
# Date: 20161109
# Function: 自动化配置代理商ftp接入方式

declare -A serverConf=(
    ['proxy']='/opt/etc/nginx/agent_server_name.conf' 
    ['dg-partner']='/opt/etc/nginx/agent_common_server_name.conf'
)
ftpConfTmp='/opt/etc/nginx/vhosts/agent/agent-ftp.template' #在dg-partner上的ftp接入配置文件模版

function get_args {
    read -p "input the ftp account: " ftpAccount
    read -p "input the ftp password: " ftpPass
    read -p "input the agent domain name: " agentDomainName
    [[ -z $ftpAccount || -z $ftpPass || -z $agentDomainName ]] && \
    echo "args can not be empty" && exit 1
    ftpConf=$(dirname $ftpConfTmp)/${agentDomainName}.conf #dg-partner上ftp接入代理商的nginx配置文件
}

function add_ftp_account {
    ssh -T dg-partner << END
echo -e "${ftpAccount}\n${ftpPass}"  >> /etc/vsftpd/vu_list.txt
db_load -T -t hash -f /etc/vsftpd/vu_list.txt /etc/vsftpd/vu_list.db

cat > /etc/vsftpd/vu_config/$ftpAccount <<EOF
anon_world_readable_only=NO
write_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
local_root=/data/ftp/$ftpAccount
EOF

mkdir -pv /data/ftp/$ftpAccount
cp -a /data/www/ddos_v2/public/web_agent/ /data/ftp/${ftpAccount}/
rm -f /data/ftp/${ftpAccount}/web_agent/index.php
chown -R nginx:nginx /data/ftp/$ftpAccount 

END
}

function add_nginx_conf {
    local i
    for i in ${!serverConf[*]}; do
        if [[ $i == 'dg-partner' ]]; then
            ssh -T $i << END
cp $ftpConfTmp $ftpConf
sed -i "s/#serverName#/${agentDomainName}/" $ftpConf
sed -i "s/#ftpDir#/${ftpAccount}/" $ftpConf
END
        fi

        ssh -T $i << END
echo -e "server_name ${agentDomainName};" >> ${serverConf[$i]}
nginx -t && nginx -sreload
END

    done
}

function del_ftp_account {
    ssh -T dg-partner << END
sed -i "/$ftpAccount/,+1d" /etc/vsftpd/vu_list.txt
[[ -f /etc/vsftpd/vu_list.db ]] && rm -f /etc/vsftpd/vu_list.db
db_load -T -t hash -f /etc/vsftpd/vu_list.txt /etc/vsftpd/vu_list.db
[[ -f /etc/vsftpd/vu_config/$ftpAccount ]] && \
rm -f /etc/vsftpd/vu_config/$ftpAccount && echo "delete ftp virtual user conf /etc/vsftpd/vu_config/$ftpAccount done."
[[ -d /data/ftp/$ftpAccount ]] && \
rm -rf /data/ftp/$ftpAccount && echo "delete ftp user data dir /data/ftp/$ftpAccount done."
END
}

function del_nginx_conf {
    local i
    for i in ${!serverConf[*]}; do
        if [[ $i == 'dg-partner' ]]; then
            ssh -T $i << END
[[ -f $ftpConf ]] && rm -f $ftpConf && echo "delete dg-partner nginx conf $ftpConf done."
END
        fi 
    
        ssh -T $i << END
sed -i "/$agentDomainName/d" ${serverConf[$i]}
nginx -t && nginx -sreload
END
    done
}

case $1 in 
    'add')
        get_args
        add_ftp_account
        add_nginx_conf
        ;;
    'del')
        get_args
        del_ftp_account
        del_nginx_conf
        ;;
    *)
        echo "invalid args.[add|del]" && exit 10
        ;;
esac

