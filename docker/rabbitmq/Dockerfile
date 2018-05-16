FROM rabbitmq:3.7.4-management

EXPOSE 4369 5671 5672 25672 15671 15672
CMD ["rabbitmq-server"]

RUN apt-get update && apt-get install -y procps vim-tiny iputils-ping

#修改locale支持中文显示和编辑
RUN apt-get update && apt-get install -y locales \
    && rm -r /var/lib/apt/lists/* \
    && sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen
