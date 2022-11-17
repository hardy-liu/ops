FROM redis:5.0.8

RUN apt-get update && apt-get install -y procps vim-tiny iputils-ping

#修改locale支持中文显示和编辑
RUN apt-get update && apt-get install -y locales \
    && rm -r /var/lib/apt/lists/* \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen

#更改redis用户uid和gid, 同时更新目录权限
RUN usermod -u 10002 redis \
    && groupmod -g 10002 redis \
    && chown -R redis:redis /data
