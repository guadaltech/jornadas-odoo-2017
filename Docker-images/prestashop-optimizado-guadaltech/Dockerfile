FROM php:5.6-apache
MAINTAINER Juan Manuel Torres <juanmanuel.torres@guadaltech.es>
# https://github.com/Tedezed

ENV PS_DOMAIN <to be defined>
ENV DB_SERVER 127.0.0.1
ENV DB_PORT 3306
ENV DB_NAME prestashop
ENV DB_USER root
ENV DB_PASSWD admin
ENV ADMIN_MAIL demo@prestashop.com
ENV ADMIN_PASSWD passdemo
ENV PS_LANGUAGE es
ENV PS_COUNTRY es
ENV PS_INSTALL_AUTO 0
ENV PS_DEV_MODE 0
ENV PS_HOST_MODE 0
ENV PS_HANDLE_DYNAMIC_DOMAIN 0
ENV PS_FOLDER_ADMIN admin5959
ENV PS_FOLDER_INSTALL install
ENV PS_THEME "0"
ENV FIRSTNAME John
ENV LASTNAME Doe
ENV PRESTAERP_URL http://localhost
ENV PRESTAERP_PORT 8069
ENV PRESTAERP_USERNAME root
ENV PRESTAERP_PASS root
ENV PRESTAERP_DB odoo_db
ENV PS_WEBSERVICE_KEY Y5I1GBXZB1EXJ3ZNEZ7Y4JY2OWL8EGRC
ENV MULTISHOP 0
ENV LIST_GROUP_MULTISHOP "Grupo_ejemplo_tienda1 Grupo_ejemplo_tienda2 Grupo_ejemplo_tienda3"
ENV DIC_SHOPS '( ["Grupo_ejemplo_tienda1"]="tienda1 tienda2 tienda3" ["Grupo_ejemplo_tienda3"]="tienda_g2_1")'
ENV PS_CLEAR 0
ENV PS_CONF_ODOO_AUTO 0

RUN apt-get update \
	&& apt-get install -y libmcrypt-dev \
		libjpeg62-turbo-dev \
		libpng12-dev \
		libfreetype6-dev \
		libxml2-dev \
		libicu-dev \
		mysql-client \
		wget \
		unzip \
		git \
		python \
		nano \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install iconv intl mcrypt opcache pdo mysql pdo_mysql mbstring soap gd zip

ENV PS_VERSION 1.6.0.9

ADD files/html.org/ /tmp/html.org/
ADD files/html.theme/ /tmp/html.theme/
RUN ls /tmp

RUN a2enmod env
RUN a2enmod rewrite
RUN a2enmod headers
RUN chown www-data:www-data -R /var/www/html/

RUN mkdir /tmp/gst_pob_connector
ADD files/gst_pob_connector /tmp/gst_pob_connector

https://github.com/Tedezed/prestashop_console/raw/master/bin/prestashopConsole.phar /var/www/html/prestashopConsole.phar
RUN chmod +x /var/www/html/prestashopConsole.phar

ADD files/000-default.conf /etc/apache2/sites-available/000-default.conf

ADD files/ps-clear.sql /tmp/ps-clear.sql

COPY config_files/docker_run.sh /tmp/
COPY config_files/docker-optimizado.sh /tmp/
RUN chmod +x /tmp/*
RUN rm -rf /var/www/html/*

VOLUME /var/www/html

CMD ["/tmp/docker-optimizado.sh"]
