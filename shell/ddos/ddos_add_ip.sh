#!/bin/bash
#添加节点IP和VIP
#备用0，东莞1，厦门2，北京3，监控11
#节点：dg-ngx[01-12].fanghubao.com, xm-ngx[01-12].fanghubao.com
#IP：183.2.194.0/24[东莞], 120.41.39.0/24[厦门] 

database=ddos
table=wy_ip
dbUser=root
dbPass=fhbdb@wy
ipPrefixXM=120.41.39
ipPrefixDG=183.2.194
nodePrefixXM=xm-ngx
nodePrefixDG=dg-ngx

#添加厦门IP
for i in {1..252};do
    location=2
    ip=${ipPrefixXM}.$i
    mysql -u${dbUser} -p${dbPass} -e "insert into ${database}.${table} (ip,idc) values ('$ip',$location);" \
    && echo "add ip $ip done."
done

#添加东莞IP
for i in {1..252};do
    location=1
    ip=${ipPrefixDG}.$i
    mysql -u${dbUser} -p${dbPass} -e "insert into ${database}.${table} (ip,idc) values ('$ip',$location);" \
    && echo "add ip $ip done."
done

#添加备用节点，将东莞的183.2.194.254和厦门的120.41.39.254添加为备用IP
mysql -u${dbUser} -p${dbPass} -e "insert into ${database}.${table} (ip,idc) values ('183.2.194.253',0);"
mysql -u${dbUser} -p${dbPass} -e "insert into ${database}.${table} (ip,idc) values ('183.2.194.254',0);"
mysql -u${dbUser} -p${dbPass} -e "insert into ${database}.${table} (ip,idc) values ('120.41.39.253',0);"
mysql -u${dbUser} -p${dbPass} -e "insert into ${database}.${table} (ip,idc) values ('120.41.39.254',0);"
[[ $? -eq 0 ]] && echo "add backup IP done." || exit 100

#添加厦门节点
for i in {01..12};do
    location=11
    node=${nodePrefixXM}${i}.fanghubao.com
    mysql -u${dbUser} -p${dbPass} -e "insert into ${database}.${table} (url,idc) values ('$node',$location);" \
    && echo "add node $node done."
done

#添加东莞节点
for i in {01..12};do
    location=11
    node=${nodePrefixDG}${i}.fanghubao.com
    mysql -u${dbUser} -p${dbPass} -e "insert into ${database}.${table} (url,idc) values ('$node',$location);" \
    && echo "add node $node done."
done
