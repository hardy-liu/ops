#!/bin/bash
# Author: liudian
# Date: 20161122
# Function: 清空测试环境的数据库

dbUser='root'
dbPass='newpasswd@ddos'
dbBakDir='/tmp'
dbBakNameSuffix="$(date "+%F").sql"
#ddos数据库应该保留的表
ddosReservedTable="(admin_permission|admin_role|admin_role_permission|admin_user|wy_article|wy_article_cate|wy_auto_script_log|wy_config|wy_domain_black_list|wy_domain_preg|wy_idc_ip|wy_ip|wy_ip_center|wy_package|wy_price|w
y_price_benefit|wy_product|wy_shop|wy_shop_c|wy_shop_c_ip|wy_shop_ip)"

function bk_db {
    mysqldump -u${dbUser} -p${dbPass} --database $1 > ${dbBakDir}/${1}_${dbBakNameSuffix} && \
    echo "dump $1 done."
}

function clean_ddos {
    local i dirtyTables
    dirtyTables=$(mysql -u${dbUser} -p${dbPass} -e "show tables from ddos" | sed -n '2,$p' | egrep -v -w $ddosReservedTable)
    for i in $dirtyTables; do
        mysql -u${dbUser} -p${dbPass} -e "truncate table ddos.$i;" && echo "truncate ddos.$i done."
    done
    #释放已关联的ip
    mysql -u${dbUser} -p${dbPass} -e "update ddos.wy_ip set did=0;" && echo "release wy_ip done."
}

function clean_ipstatus {
    local i dirtyTables
    dirtyTables=$(mysql -u${dbUser} -p${dbPass} -e "show tables from ipstatus;" | sed -n '2,$p')
    for i in $dirtyTables; do
        mysql -u${dbUser} -p${dbPass} -e "truncate table ipstatus.$i;" && echo "truncate ipstatus.$i done."
    done
}

function restart_service {
    systemctl restart nginx
    systemctl restart php56-php-fpm
    systemctl restart supervisord
}

bk_db ddos
clean_ddos
bk_db ipstatus
clean_ipstatus
restart_service