FROM php:7.4-fpm

#安装ps和vim命令行工具
#RUN apt-get update && apt-get install -y apt-utils
RUN apt-get update -y && apt-get install -y apt-utils procps vim-tiny inetutils-ping

#安装扩展
RUN apt-get update -y && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        #libmcrypt-dev \ #mcrypt在php 7.2中被移除
        libpng-dev \
        libxml2-dev \
        libzip-dev \
        libgmp-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) xmlrpc pdo_mysql mysqli bcmath soap zip gmp sockets pcntl
    #pdo and iconv already included in the base image

#安装pecl-redis扩展
RUN pecl install redis && docker-php-ext-enable redis
#安装pecl-mongodb扩展
RUN pecl install mongodb && docker-php-ext-enable mongodb
#安装swoole
RUN pecl install swoole && docker-php-ext-enable swoole 

#更改php配置
RUN mkdir -p /data/php/log \
    && mkdir -p /data/php/session \
    && cd /usr/local/etc \
    && { \
        echo 'post_max_size = 32M'; \
        echo 'upload_max_filesize = 32M'; \
        echo 'date.timezone = Asia/Shanghai'; \
        echo 'max_execution_time = 300'; \
        echo 'expose_php = Off'; \
    } | tee php/php.ini; \
    for i in php-fpm.d/www.conf; do \
            sed -i 's/pm.max_children = 5/pm.max_children = 500/' $i; \
            sed -i 's/;request_slowlog_timeout = 0/request_slowlog_timeout = 3s/' $i; \
            sed -i 's@;slowlog = log/$pool.log.slow@slowlog = /data/php/log/www-slow.log@' $i; \
            sed -i 's@;php_admin_value\[error_log\] = /var/log/fpm-php.www.log@php_admin_value\[error_log\] = /data/php/log/www-error.log@' $i; \
    done; \
    echo 'php_value[session.save_path] = /data/php/session' >> php-fpm.d/www.conf; \
    for i in php-fpm.d/docker.conf; do \
            sed -i 's@error_log = /proc/self/fd/2@error_log = /data/php/log/error.log@' $i; \
            sed -i 's@access.log = /proc/self/fd/2@access.log = /data/php/log/access.log@' $i; \
    done;

#安装composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#安装git，不然composer install某些包装不上
RUN apt-get update && apt-get install -y git

#修改locale支持中文显示和编辑
RUN apt-get update && apt-get install -y locales \
    && rm -r /var/lib/apt/lists/* \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen

#更改www-data用户uid和gid, 同时更新目录权限
RUN usermod -u 10003 www-data \
    && groupmod -g 10003 www-data
