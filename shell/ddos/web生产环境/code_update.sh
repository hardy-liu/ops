#!/bin/bash
# Author: liudian
# Date: 2016-08-15
# Function: git更新, 回滚, gulp dg-www和dg-partner上的代码

codeDir='/data/www/ddos_v2'
host=('dg-www' 'dg-partner')

function pull {
    ssh $1 "cd $codeDir;git pull"
    
    if [ "$?" -ne 0 ] ;then
        echo "pull error"
        exit 1
    fi
 
    if [[ $1 == 'dg-www' ]]; then
        read -p "please intput the tag name: " tagName
        read -p "please intput the tag comment: " tagComment
        ssh $1 "cd $codeDir;git tag -a $tagName -m $tagComment;git push origin --tags"
        ssh $1 "supervisorctl status | grep 'queueListen' | cut -d' ' -f1 | xargs -i supervisorctl restart {}"
    fi
}

function reset {
    read -p "which tag do you wanna roll back to: " tagName
    ssh $1 "cd $codeDir;git reset --hard $tagName"
}

function validate_args {
    if ! echo "${validArgs[*]}" | grep -w "$1" &> /dev/null; then
        echo "invalid args.[pull|reset]"
        exit 1
    fi
}

function gulp {
    ssh $1 "cd ${codeDir}/public/html_back_v2/;gulp"
    ssh $1 "cd ${codeDir}/public/html_www_v2.1/;gulp"
    ssh $1 "cd ${codeDir}/public/html_agent_v2.5/;gulp"
}

validArgs=('pull' 'reset' 'gulp');
validate_args $1

for i in ${host[*]}; do
    $1 $i
done
