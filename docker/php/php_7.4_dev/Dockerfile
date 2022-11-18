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
        libmagickwand-dev \
        imagemagick \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install -j$(nproc) xmlrpc pdo_mysql mysqli bcmath soap zip gmp sockets pcntl
    #pdo and iconv already included in the base image

#安装opcache
#RUN docker-php-ext-install opcache
#安装pecl-redis扩展
RUN pecl install redis && docker-php-ext-enable redis
#安装pecl-mongodb扩展
RUN pecl install mongodb && docker-php-ext-enable mongodb
#安装swoole
#RUN pecl install swoole && docker-php-ext-enable swoole 
#安装imagick
RUN pecl install imagick && docker-php-ext-enable imagick
#安装xdebug扩展
RUN pecl install xdebug && docker-php-ext-enable xdebug
#配置xdebug
RUN echo "xdebug.mode=develop,debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_port=9001" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.discover_client_host=0" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo 'xdebug.start_with_request=yes' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Use the default dev configuration
RUN cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
#更改php配置
RUN mkdir -p /data/php/log \
    && mkdir -p /data/php/session \
    && cd /usr/local/etc \
    && for i in php/php.ini; do \
            sed -i 's/post_max_size = 8M/post_max_size = 32M/' $i; \
            sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 32M/' $i; \
            sed -i 's@;date.timezone =@date.timezone = Asia/Shanghai@' $i; \
            sed -i 's/max_execution_time = 30/max_execution_time = 300/' $i; \
    done; \
    for i in php-fpm.d/www.conf; do \
            sed -i 's/pm.max_children = 5/pm.max_children = 500/' $i; \
            sed -i 's/;request_slowlog_timeout = 0/request_slowlog_timeout = 1s/' $i; \
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
