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
RUN a2enmod headers
RUN a2enmod rewrite

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Update the default apache site with the config we created.
ADD ./docker/apache/olam-dev.conf /etc/apache2/sites-enabled/000-default.conf

# Update php.ini files
ADD ./docker/php/xdebug.ini /etc/php/7.0/mods-available/xdebug.ini

# Set the xdebug remote host to the default gateway that is defined in the docker compose file
# Right now we set just the subnet because gateway isn't supported, but the gateway should be the #.#.#.1 address
RUN echo "xdebug.remote_host=172.20.0.1" >> /etc/php/7.0/mods-available/xdebug.ini

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

# Download Composer Installer
RUN curl --silent --fail --location --retry 3 --output /tmp/installer.php --url https://getcomposer.org/installer

# Install Composer
RUN php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer \
&& composer --ansi --version --no-interaction \
&& rm -f /tmp/installer.php

COPY ./docker/docker-entrypoint.sh /usr/local/bin/docker_httpd
RUN chmod u+x /usr/local/bin/docker_httpd

CMD ["docker_httpd"]

# Build using Docker Compose
