FROM mycentos-systemd:7.4.1708

#install utils
RUN yum install -y net-tools lsof

#install repo
COPY ./shadowsocks-server.repo /etc/yum.repos.d/shadowsocks-server.repo
RUN yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
    && yum install -y mbedtls-devel libsodium13 shadowsocks-qt5 shadowsocks-libev \
    && mv /etc/shadowsocks-libev/{config.json,config.json.default} \
    && sed -i 's/Group=$GROUP/#Group=$GROUP/' /usr/lib/systemd/system/shadowsocks-libev.service \
    && yum clean all
COPY ./config.json /etc/shadowsocks-libev/config.json
#fix missing dynamci library
RUN [[ ! -f /usr/lib64/libmbedcrypto.so.0 ]] && ln -sv /usr/lib64/{libmbedcrypto.so.1,libmbedcrypto.so.0}

#start service
RUN systemctl enable shadowsocks-libev.service

EXPOSE 8388
