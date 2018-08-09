FROM mongo:4.0.0

RUN apt-get update && apt-get install -y procps vim

#修改locale支持中文显示和编辑
RUN apt-get update && apt-get install -y locales \
    && rm -r /var/lib/apt/lists/* \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen

#更改mongodb用户uid和gid, 同时更新目录权限
RUN usermod -u 10005 mongodb \
    && groupmod -g 10005 mongodb \
    && chown -R mongodb:mongodb /data \
    && chown -R mongodb:mongodb /var/log/mongodb
