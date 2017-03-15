#!/bin/bash
#Function: 打印连接过程中的各种属性
#Date: 2016-08-02
curl -s -w "http_code: %{http_code}
remote_ip: %{remote_ip}
time_namelookup: %{time_namelookup}
time_connect: %{time_connect}
time_appconnect: %{time_appconnect}
time_pretransfer: %{time_pretransfer}
time_starttransfer: %{time_starttransfer}
time_total: %{time_total}
size_request: %{size_request}
size_download: %{size_download}
speed_download: %{speed_download}\n" $*
