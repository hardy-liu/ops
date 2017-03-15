#!/bin/bash
# Date: 2016-01-04
# Author: Liudian
# 更新om代码,从测试环境scp代码到生产环境，使用git之后不再需要此脚本
code_dir=/data/www/oumoo
bk_dir=/codebackup/$(date "+%F")
remote_server=10.1.1.103
remote_port=8400
log_file=/codebackup/code_update.log

code_backup() {
    cp -r $1 $2 1> /dev/null
    if [ $? -eq 0 ]; then
        echo "$(date "+%F %T") backup $1 done." >> $3
    else
        exit 1
    fi
}

code_update() {
    scp -r -l40960 -P$1 $2 $3 1> /dev/null
    if [ $? -eq 0 ]; then
        echo "$(date "+%F %T") update $3 done." >> $4 
    else
        exit 2
    fi
} 

# When update dir, Don't add slash("/") after the name of the dir.
read -p "which file or dir you wanna update?[/data/www/oumoo/]" code
[ ${code_dir}${code} == $code_dir ] && exit 10

local_file=${code_dir}/${code}
remote_file=${remote_server}:${local_file}
back_file=${bk_dir}/${code}_$(date +%T)

if [ -f $local_file ]; then
    [ ! -d ${back_file%/*} ] && mkdir -p ${back_file%/*}
    code_backup $local_file $back_file $log_file
	[ $? -eq 0 ] && echo "backup $local_file done."
    code_update $remote_port $remote_file $local_file $log_file
	[ $? -eq 0 ] && echo "update $local_file done."
elif [ -d $local_file ]; then
    [ ! -d ${back_file%/*} ] && mkdir -p ${back_file%/*}
    code_backup $local_file $back_file $log_file
	[ $? -eq 0 ] && echo "backup $local_file done."
    code_update $remote_port ${remote_file}/* $local_file $log_file
	[ $? -eq 0 ] && echo "update $local_file done."
else
    code_update $remote_port $remote_file $local_file $log_file
	[ $? -eq 0 ] && echo "update $local_file done."
fi
