#!/bin/bash
#删除1天之前的Cache缓存文件,跑在web（10.1.1.3）上
Cache_dir=/data/www/oumoo/Cache/js/
Outdated_file=$(find $Cache_dir -mmin +1440)

purge (){
for i in $*; do
    File_mtime=$(ls -l $i | awk '{print $6,$7,$8}')
    rm -f $i
    [ $? -eq 0 ] && echo "$(date +%F_%T) delete $i $File_mtime done." >> /tmp/purge_Cache_file.log
done
}
purge $Outdated_file
