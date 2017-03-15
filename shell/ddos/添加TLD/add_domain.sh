#!/usr/bin/env bash
#
insertValue=''
while read i; do
	insertValue+="('$i'),"
done < ./TLD-2.txt
#echo ${insertValue%,}
mysql -uroot -pnewpasswd@ddos -e "insert into ddos.wy_domain_preg (domain) values ${insertValue%,};"
