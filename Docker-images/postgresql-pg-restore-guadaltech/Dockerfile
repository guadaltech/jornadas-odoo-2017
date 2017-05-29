FROM debian:jessie
MAINTAINER Juan Manuel Torres <juanmanuel.torres@aventurabinaria.es>
# https://github.com/Tedezed

ENV POSTGRES_USER odoo
ENV POSTGRES_PASSWORD odoo
ENV POSTGRES_DB odoo
ENV POSTGRES_PORT 5432
ENV USER_MOBILE xxx
ENV USER_MOBILE_PASS xxx
ENV NUM_CUENTA "2261 1134 84 0270267018"
ENV LOGO_BASE64 ""
ENV CONF_NOMBRE odoo-test
ENV CONF_CALLE nom-calle
ENV CONF_CIUDAD Sevilla
ENV CONF_COD_ZIP 40000
ENV CONF_WEB web-test.com
ENV CONF_TELF 000000
ENV CONF_TELF_MOVIL 0000000
ENV CONF_MAIL TUEMAIL@EMAIL.COM
ENV CONF_DNI 93723034N
ENV ODOO_USER xxx
ENV ODOO_PASS xxx
ENV MYSQL_SERVER mysql-test
ENV MYSQL_PASSWD root
ENV PS_WEBSERVICE_KEY Y5I1GBXZB1EXJ3ZNEZ7Y4JY2OWL8EGRC
ENV PS_DOMAIN "http://ps.test.freyishop.es"
ENV ODOO_TYPE simple

RUN groupadd -r postgres --gid=999 && useradd -r -g postgres --uid=999 postgres

ENV GOSU_VERSION 1.7

RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& apt-get purge -y --auto-remove ca-certificates wget

RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN mkdir /docker-entrypoint-initdb.d

RUN set -ex; \
# pub   4096R/ACCC4CF8 2011-10-13 [expires: 2019-07-02]
#       Key fingerprint = B97B 0AFC AA1A 47F0 44F2  44A0 7FCC 7D46 ACCC 4CF8
# uid                  PostgreSQL Debian Repository
	key='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	gpg --export "$key" > /etc/apt/trusted.gpg.d/postgres.gpg; \
	rm -r "$GNUPGHOME"; \
	apt-key list

ENV PG_MAJOR 9.4
ENV PG_VERSION 9.4.11-1.pgdg80+1
#ENV PG_VERSION 9.4

RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update \
	&& apt-get install -y postgresql-common \
	&& sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf \
	&& apt-get install -y \
		postgresql-$PG_MAJOR \
		postgresql-contrib-$PG_MAJOR \
	&& rm -rf /var/lib/apt/lists/*

RUN mv -v /usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample /usr/share/postgresql/ \
	&& ln -sv ../postgresql.conf.sample /usr/share/postgresql/$PG_MAJOR/ \
	&& sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample

RUN mkdir -p /var/run/postgresql && chown -R postgres:postgres /var/run/postgresql && chmod g+s /var/run/postgresql

ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
ENV PGDATA /var/lib/postgresql/data
RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 700 "$PGDATA" # this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)

RUN apt-get update \
	&& apt-get install -y \
		sudo \
		nano \
	&& rm -rf /var/lib/apt/lists/*

RUN sed -i 's|"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"|"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/postgresql/9.4/bin/"|g' /etc/sudoers
RUN mkdir /odoo-prostgres
ADD files/ /odoo-prostgres/
RUN chmod +x /odoo-prostgres/restore-odoo.sh

ARG DB_RESTORE
ENV DB_RESTORE $DB_RESTORE

COPY docker-inicial.sh /
RUN chmod +x /docker-inicial.sh
RUN /docker-inicial.sh postgres

RUN mkdir /backup
RUN cp -R /var/lib/postgresql /backup

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

VOLUME /var/lib/postgresql

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]