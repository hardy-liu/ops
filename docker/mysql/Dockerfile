FROM mysql:5.7.22

RUN apt-get update && apt-get install -y procps vim-tiny

#自定义配置
ADD ./custom.conf.d /etc/mysql/custom.conf.d
RUN echo "!includedir /etc/mysql/custom.conf.d/" >> /etc/mysql/my.cnf

#更新配置
RUN echo "user=mysql" >> /etc/mysql/mysql.conf.d/mysqld.cnf
