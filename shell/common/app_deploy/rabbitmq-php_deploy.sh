#/bin/bash
# Author: liudian
# Data: 2016-03-17
# Function: PHP的rabbitmq扩展的自动安装脚本
# Usage: 将脚本和软件包放置于同一目录然后执行此脚本

source /data/shell/pub_function.sh #引入公共函数

basePackages=(openssl-devel php-devel cmake) #依赖包
deployDir=$(pwd) #软件包所在目录
rabbitmq='rabbitmq-c-0.7.1.tar.gz' #rabbitmq-c的软件包名称
amqp='amqp-1.6.1.tgz' #php的amqp扩展的软件包名称
logFile='/data/log/rabbitmq_deploy.log'

#安装依赖包
for i in ${basePackages[*]}; do
	rpm -ql $i &> /dev/null
	if [[ ! $? -eq 0 ]]; then
		yum -y install $i && write_log "install $i done." $logFile
	else
		write_log "$i alreay installed." $logFile
	fi
done

#安装rabbitmq-c
cd $deployDir
tar xf $rabbitmq
cd ${rabbitmq%%.tar.gz}
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/lib64/rabbitmq ..
cmake --build . --target install
ln -sv /usr/lib64/rabbitmq/include /usr/include/rabbitmq
echo "/usr/lib64/rabbitmq/lib64/" > /etc/ld.so.conf.d/rabbitmq.conf 
ldconfig
write_log "rabbitmq-c installed done." $logFile

#安装php的amqp的扩展
cd $deployDir
tar xf $amqp
cd ${amqp%%.tgz}
eval $(which phpize)
./configure --with-php-config=$(which php-config) --with-amqp --with-librabbitmq-dir=/usr/lib64/rabbitmq --with-libdir=/lib64
make && make install
echo "extension=amqp.so" > /etc/php.d/amqp.ini 
write_log "amqp-php installed done." $logFile
