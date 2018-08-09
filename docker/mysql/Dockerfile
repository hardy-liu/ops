FROM mysql:5.7.22

RUN apt-get update && apt-get install -y procps vim-tiny

#自定义配置
ADD ./custom.conf.d /etc/mysql/custom.conf.d
RUN echo "!includedir /etc/mysql/custom.conf.d/" >> /etc/mysql/my.cnf

#修改locale支持中文显示和编辑
RUN apt-get update && apt-get install -y locales \
    && rm -r /var/lib/apt/lists/* \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen

#更新配置
RUN echo "user=mysql" >> /etc/mysql/mysql.conf.d/mysqld.cnf \
    && echo "log_timestamps=SYSTEM" >> /etc/mysql/mysql.conf.d/mysqld.cnf \
    && sed -i "s/#log-error/log-error/" /etc/mysql/mysql.conf.d/mysqld.cnf

#更改mysql用户uid和gid, 同时更新目录权限
RUN usermod -u 10001 mysql \
    && groupmod -g 10001 mysql \
    && chown -R mysql:mysql /var/log/mysql \
    && chown -R mysql:mysql /var/lib/mysql
