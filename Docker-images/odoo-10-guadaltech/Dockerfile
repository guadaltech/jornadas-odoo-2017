FROM debian:jessie
MAINTAINER Juan Manuel Torres <juanmanuel.torres@guadaltech.es>
# https://github.com/Tedezed

ENV ODOO_TYPE simple
ENV KMINION simple
ENV PS_DOMAIN simple
ENV MASTER_PASS admin

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            nano \
            git \
            node-less \
            python-gevent \
            python-pip \
            python-renderpm \
            python-support \
            python-watchdog \
        && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
        && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb \
        && apt-get -y install -f --no-install-recommends \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb \
        && pip install psycogreen==1.0

RUN apt-get update \
    && apt-get install -y \
        python-pycountry \
    && rm -rf /var/lib/apt/lists/*

ENV ODOO_VERSION 10.0
ENV ODOO_RELEASE 20170207
RUN set -x; \
        curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/odoo_${ODOO_VERSION}.${ODOO_RELEASE}_all.deb \
        && echo '5d2fb0cc03fa0795a7b2186bb341caa74d372e82 odoo.deb' | sha1sum -c - \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb

RUN apt-get update \
    && apt-get -y install gcc make build-essential libssl-dev libffi-dev python-pip python-dev libmysqlclient-dev sudo unicode python-unicodecsv python-xlrd python-xlwt \
    && rm -rf /var/lib/apt/lists/* 
RUN pip install MySQL-python
RUN pip install unidecode
RUN echo "odoo   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir -p /mnt/extra-addons \
    && chown -R odoo:odoo /mnt/extra-addons \
    && chown -R odoo:odoo /var/lib/odoo

EXPOSE 8069 8071

ENV ODOO_RC /etc/odoo/odoo.conf
ADD files/ /mnt/extra-addons/

COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
RUN chown odoo /etc/odoo/odoo.conf

RUN mkdir /conf-odoo
RUN cp /etc/odoo/* /conf-odoo

RUN mkdir /mnt/external-addons
VOLUME ["/var/lib/odoo", "/mnt/external-addons", "/etc/odoo"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
