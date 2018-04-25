FROM nginx:1.12.2

# 添加自定义的配置文件
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.default
ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./customized /etc/nginx/customized

RUN rm -f /etc/nginx/conf.d/default.conf
ADD ./example-host.conf /etc/nginx/conf.d/example-host.conf
