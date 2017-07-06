# Centos 7 + nginx 10/php 7
FROM centos:centos7

MAINTAINER Jimmy Ruska: 0.2

WORKDIR /root/

RUN \
 yum -y install epel-release ; \  
 rpm -Ui https://centos7.iuscommunity.org/ius-release.rpm ; \
 rpm -Ui https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm; \
 yum -y update ; \  
 yum install -y nginx umod_php71u php71u-cli php71u-mysqlnd php71u-pgsql  php71u-fpm php71u-fpm-nginx  redis32u vim tmux curl openssl-devel less php71u-json git python python36u python36u-pip php71u-devel gcc php71u-devel postgresql96; \
 pip3.6 install awscli ; \
 useradd -r www-data ; \  
 usermod -aG www-data nginx ; \  
 usermod -aG www-data php-fpm ; \
 echo -e "session.save_handler = redis\nsession.save_path = 'unix:///var/run/redis.sock?persistent=1&weight=1'" >> /etc/php.ini; \
 echo -e "port 0\nbind 127.0.0.1\nunixsocket /var/run/redis.sock\nunixsocketperm 755" >> /etc/redis.conf; \
 cd ~/ && git clone https://github.com/igbinary/igbinary.git && cd igbinary; \
 phpize && ./configure && make && make install; \
 echo -e "extension=igbinary.so\nsession.serialize_handler=igbinary\nigbinary.compact_strings=On" >> /etc/php.ini; \
 cd ~/ && git clone https://github.com/phpredis/phpredis.git && cd phpredis && phpize --enable-redis-igbinary && ./configure && make && make install; \
 echo "extension=redis.so" > /etc/php.d/30-redis.ini; \
 echo "listen = /run/php-fpm/php-fpm.sock" >> /etc/php-fpm.d/www.conf ; \  
 echo "cgi.fix_pathinfo=0" >> /etc/php.ini ; \  
 echo "upstream php-fpm { server unix:/run/php-fpm/php-fpm.sock; }" > /etc/nginx/conf.d/php-fpm.conf ; \  
 echo -e "listen.owner = nginx\nlisten.group = nginx\nuser = nginx\ngroup = nginx\n" >> /etc/php-fpm.d/www.conf; \
 echo -e "#!/bin/bash\n\n/usr/sbin/php-fpm && redis-server --daemonize yes && /usr/sbin/nginx -g 'daemon off;'" > /usr/bin/start-nginx.sh; \
 rm -rf /usr/share/nginx/html/; \
 mkdir -p /usr/share/nginx/html; \
 chmod +x /usr/bin/start-nginx.sh; \
 sed -i 's@http {@http {\n\tserver_tokens off;\n\tadd_header X-Content-Type-Options nosniff;\n\tadd_header X-XSS-Protection "1; mode=block";\n@g' /etc/nginx/nginx.conf; \
 sed -i 's@server {@server {\n\tindex index.php index.html;\n@g' /etc/nginx/nginx.conf;

VOLUME ["/usr/share/nginx/html/", "/var/log/nginx/", "/var/log/php-fpm/"]

CMD ["/usr/bin/start-nginx.sh"]


EXPOSE 80
EXPOSE 443