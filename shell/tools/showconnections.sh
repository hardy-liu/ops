#!/bin/bash
#查看tcp连接情况
ss -anp | awk '/^tcp/{STAT[$2]++}END{for (a in STAT) print a,STAT[a]}'
