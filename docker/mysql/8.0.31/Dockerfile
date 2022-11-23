FROM mysql:8.0.31

#oracle linux has no apt-get
RUN microdnf install -y procps vim iputils && microdnf clean all

#vim支持中文
RUN echo "set fileencodings=ucs-bom,utf-8,latin1" >> /etc/vimrc \
    && echo "set termencoding=utf-8" >> /etc/vimrc \
    && echo "set fileformats=unix" >> /etc/vimrc \
    && echo "set encoding=prc" >> /etc/vimrc 

#创建日志目录并设置权限
RUN mkdir /var/log/mysql
RUN usermod -u 10001 mysql \
    && groupmod -g 10001 mysql \
    && chown -R mysql:mysql /var/log/mysql \
    && chown -R mysql:mysql /var/lib/mysql
