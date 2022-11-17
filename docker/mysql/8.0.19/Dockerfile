FROM mysql:8.0.19

RUN apt-get update && apt-get install -y procps vim-tiny iputils-ping

#自定义配置，使用volumes映射加载额外配置
#ADD ./custom.conf.d /etc/mysql/custom.conf.d
RUN echo "!includedir /etc/mysql/custom.conf.d/" >> /etc/mysql/my.cnf

#更新配置
RUN echo "user=mysql" >> /etc/mysql/conf.d/docker.cnf \
    && echo "log_timestamps=SYSTEM" >> /etc/mysql/conf.d/docker.cnf \
    && echo "log-error = /var/log/mysql/error.log" >> /etc/mysql/conf.d/docker.cnf

#修改locale支持中文显示和编辑
RUN apt-get update && apt-get install -y locales \
    && rm -r /var/lib/apt/lists/* \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen

#创建日志目录并设置权限
RUN mkdir /var/log/mysql
RUN usermod -u 10001 mysql \
    && groupmod -g 10001 mysql \
    && chown -R mysql:mysql /var/log/mysql \
    && chown -R mysql:mysql /var/lib/mysql
