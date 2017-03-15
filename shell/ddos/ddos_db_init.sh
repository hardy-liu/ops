#!/bin/bash

dbUser='root'
dbPass='fhbdb@wy'

#初始化防护宝数据库ddos
truncateTable=$(mysql -u${dbUser} -p${dbPass} -e "show tables from ddos" | sed -n '2,$p' | egrep -v "(wy_article|wy_article_cate|wy_config|wy_package|wy_shop|wy_shop_c|wy_shop_c_ip|wy_shop_ip|wy_domain_preg|wy_domain_black_list)")
for i in $truncateTable;do
    mysql -u${dbUser} -p${dbPass} -e "truncate table ddos.$i;"
done

#清空ipstatus库
ipstatusTables=$(mysql -u${dbUser} -p${dbPass} -e "show tables from ipstatus;" | sed -n '2,$p')
for i in $ipstatusTables; do
    mysql -u${dbUser} -p${dbPass} -e "truncate table ipstatus.$i;"
done
