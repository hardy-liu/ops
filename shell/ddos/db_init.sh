#!/bin/bash
#初始化防护宝数据库fhb
truncateTable=$(mysql -uroot -pfhbdb@wy -e "show tables from fhb" | sed -n '2,$p' | egrep -v "(wy_admin|wy_article|wy_article_cate|wy_config|wy_package|wy_shop|wy_shop_c)")
for i in $truncateTable;do
    mysql -uroot -pfhbdb@wy -e "truncate table fhb.$i;"
done

#清空ipstatus库
ipstatusTables=$(mysql -uroot -pfhbdb@wy -e "show tables from ipstatus;" | sed -n '2,$p')
for i in $ipstatusTables; do
    mysql -uroot -pfhbdb@wy -e "truncate table ipstatus.$i;"
done

