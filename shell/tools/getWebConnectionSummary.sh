#!/bin/bash
# Author: hardy
# Date: 20170505
# Function: 显示当前系统下http或https服务的连接情况

#ss -anp | awk '/^tcp/{STAT[$2]++}END{for (a in STAT) print a,STAT[a]}'
case $1 in
	'http')
		netstat -atn | awk '/:80\>/{S[$NF]++}END{for(A in S) {print A,S[A]}}'
	;;
	'https')
		netstat -atn | awk '/:443\>/{S[$NF]++}END{for(A in S) {print A,S[A]}}'
	;;
	*)
		netstat -atn | awk '/:80\>/{S[$NF]++}END{for(A in S) {print A,S[A]}}'
	;;
esac
