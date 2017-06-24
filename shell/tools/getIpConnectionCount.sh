#!/bin/bash
# Author: hardy
# Date: 20170505
# Function: 显示当前系统上所有已连接的ip的连接数

case $1 in
	'ESTABLISHED')
		netstat -n | grep 'ESTABLISHED' | awk '/^tcp/ {print $5}' | awk -F: '{print $1}' | sort | uniq -c | sort -rn
	;;
	*)
		netstat -n | awk '/^tcp/ {print $5}' | awk -F: '{print $1}' | sort | uniq -c | sort -rn
	;;
esac
