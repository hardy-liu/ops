FROM nginx:1.12.2

#安装工具
RUN apt-get update && apt-get install -y procps vim-tiny

# 添加自定义的配置文件
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.default \
    && rm -f /etc/nginx/conf.d/default.conf
ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./customized /etc/nginx/customized
ADD ./example-host.conf /etc/nginx/conf.d/example-host.conf
