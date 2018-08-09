FROM nginx:1.12.2

#安装工具
RUN apt-get update && apt-get install -y procps vim-tiny

# 添加自定义的配置文件
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.default \
    && rm -f /etc/nginx/conf.d/default.conf
ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./customized /etc/nginx/customized
ADD ./example-host.conf /etc/nginx/conf.d/example-host.conf

#修改locale支持中文显示和编辑
RUN apt-get update && apt-get install -y locales \
    && rm -r /var/lib/apt/lists/* \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen

#更改nginx用户uid和gid, 同时更新目录权限(和php-fpm:7.2.4一样)
RUN usermod -u 10003 nginx \
    && groupmod -g 10003 nginx \
    && chown -R nginx:nginx /var/log/nginx
