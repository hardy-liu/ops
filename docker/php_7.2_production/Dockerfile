FROM php:7.2.4-fpm

#安装ps和vim命令行工具
#RUN apt-get update && apt-get install -y apt-utils
RUN apt-get update && apt-get install -y procps vim-tiny

#安装扩展
RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        #libmcrypt-dev \ #mcrypt在php 7.2中被移除
        libpng-dev \
        libxml2-dev \
        libzip-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) xmlrpc pdo_mysql mysqli bcmath soap zip
    #pdo and iconv already included in the base image

#安装pecl-redis扩展
#RUN pecl install redis-4.0.9 && docker-php-ext-enable redis
RUN curl 'http://pecl.php.net/get/redis-4.0.1.tgz' -o redis-4.0.1.tgz  \
    && pecl install redis-4.0.1.tgz \
    && docker-php-ext-enable redis \
    && rm -f redis-4.0.1.tgz

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
