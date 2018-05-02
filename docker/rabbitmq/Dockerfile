FROM rabbitmq:3.7.4-management

EXPOSE 4369 5671 5672 25672 15671 15672
CMD ["rabbitmq-server"]

RUN apt-get update && apt-get install -y procps vim-tiny iputils-ping

