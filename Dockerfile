FROM ubuntu:18.04

RUN apt-get update \
    && apt-get install -y build-essential cmake libncurses-dev bison

# de108e7ff350aa10402a3e707a4b4c75
# ADD https://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-boost-5.7.23.tar.gz /usr/src/mysql-5.7.23.tar.gz
COPY mysql-boost-5.7.23.tar.gz /usr/src/mysql-5.7.23.tar.gz

WORKDIR /usr/src

RUN tar xf mysql-5.7.23.tar.gz

RUN groupadd mysql \
    && useradd -r -g mysql -s /bin/false mysql \
	&& mkdir build \
	&& chown mysql:mysql build
	
USER mysql

WORKDIR /usr/src/build

RUN cmake ../mysql-5.7.23 -DWITH_BOOST=../mysql-5.7.23/boost/ -DSYSCONFDIR=/etc/mysql

RUN make -j 6

USER root

RUN make install

ENV PATH /usr/local/mysql/bin:$PATH

COPY my.cnf /etc/mysql/my.cnf

# From https://github.com/docker-library/mysql/blob/9d1f62552b5dcf25d3102f14eb82b579ce9f4a26/5.7/Dockerfile
RUN rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
	&& chmod 777 /var/run/mysqld \
	&& find /etc/mysql/ -name '*.cnf' -print0 \
			| xargs -0 grep -lZE '^(bind-address|log)' \
			| xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/' \
	# don't reverse lookup hostnames, they are usually another container
	&& echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 3306 33060
CMD ["mysqld"]
