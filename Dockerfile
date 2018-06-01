FROM ubuntu:xenial
MAINTAINER Matthew Devine <mdevine@connectyard.com>

RUN apt-get update -y

RUN  apt-get install -y dos2unix ntp make apache2 php7.0 libapache2-mod-php7.0 \
	php-memcached php7.0-curl php7.0-dev php7.0-gd php7.0-mysql php7.0-mbstring \
	php7.0-imap php-xdebug \
	php-pear graphviz libpcre3-dev libwww-perl libdatetime-perl libswitch-perl \
	nano less && apt-get autoremove -y && apt-get clean

# Enable apache mods.
RUN a2enmod php7.0
RUN a2enmod rewrite

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Update the default apache site with the config we created.
#ADD ./cy-server-configuration/salt-stack/apache/apache_2_4/apache2.conf /etc/apache2/apache2.conf
#ADD ./cy-server-configuration/salt-stack/apache/apache_2_4/sites/connectyard_web_dev.conf /etc/apache2/sites-enabled/000-default.conf

# Update php.ini files
#ADD ./cy-server-configuration/salt-stack/php/apache_2_4/php_7.ini /etc/php/7.0/apache2/php.ini
#ADD ./cy-server-configuration/salt-stack/php/xdebug.ini /etc/php/7.0/mods-available/xdebug.ini

# Set the xdebug remote host to the default gateway that is defined in the docker compose file
# Right now we set just the subnet because gateway isn't supported, but the gateway should be the #.#.#.1 address
#RUN echo "xdebug.remote_host=172.20.0.1" >> /etc/php/7.0/mods-available/xdebug.ini

# Expose apache.
EXPOSE 80

#Setup Mailhog as the sendmail provider
RUN apt-get update &&\
    apt-get install --no-install-recommends --assume-yes --quiet ca-certificates curl git &&\
    rm -rf /var/lib/apt/lists/*

#Install Go
RUN curl -Lsf 'https://storage.googleapis.com/golang/go1.8.3.linux-amd64.tar.gz' | tar -C '/usr/local' -xvzf -
ENV PATH /usr/local/go/bin:$PATH

#Retreive Mailhog Sendmail
RUN go get github.com/mailhog/mhsendmail
RUN cp /root/go/bin/mhsendmail /usr/bin/mhsendmail

#Tell PHP to use mailhog
RUN echo 'sendmail_path = /usr/bin/mhsendmail --smtp-addr smtp:1025' >> /etc/php/7.0/cli/php.ini
RUN echo 'sendmail_path = /usr/bin/mhsendmail --smtp-addr smtp:1025' >> /etc/php/7.0/apache2/php.ini

COPY . /var/www/html/responders

RUN echo '<?php' >> /var/www/html/responders/config.php
RUN echo '' >> /var/www/html/responders/config.php
RUN echo '# Database information goes here. Server, user, password and database.' >> /var/www/html/responders/config.php
RUN echo "\$MySQL_server   = 'mysql';" >> /var/www/html/responders/config.php
RUN echo "\$MySQL_user     = 'root';" >> /var/www/html/responders/config.php
RUN echo "\$MySQL_password = 'autoresponder';" >> /var/www/html/responders/config.php
RUN echo "\$MySQL_database = 'autoresponder';" >> /var/www/html/responders/config.php

COPY ./docker/docker-entrypoint.sh /usr/local/bin/docker_httpd
RUN chmod u+x /usr/local/bin/docker_httpd

CMD ["docker_httpd"]

# BUILD COMMAND
# Powershell: docker build -f ./Dockerfile . -t olam/web

# RUN COMMAND
# BASH:  docker run -it -v $PWD:/opt/local/connectyard --rm cy_web
# Powershell:  docker run -p 8080:80 -i -t -v ${PWD}:/opt/local/connectyard --rm olam/web /bin/bash
