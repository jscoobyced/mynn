# Setup system
FROM debian:stretch-slim
ENV DEBIAN_FRONTEND noninteractive

## Install dependencies packages
RUN set -ex; apt-get -qq update && apt-get -qq upgrade
RUN set -ex; apt-get install -qqy --no-install-recommends \
        curl gnupg vim ca-certificates apt-transport-https \
        software-properties-common dirmngr wget

# Install Netcore
RUN set -ex; wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg
RUN set -ex; mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
RUN set -ex; wget -q https://packages.microsoft.com/config/debian/9/prod.list
RUN set -ex; mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
RUN set -ex; chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
RUN set -ex; chown root:root /etc/apt/sources.list.d/microsoft-prod.list
RUN set -ex; apt-get -qq update
RUN echo mariadb-server mysql-server/root_password password 'blablabla' | debconf-set-selections
RUN echo mariadb-server mysql-server/root_password_again password 'blablabla' | debconf-set-selections
RUN set -ex; apt-get install -qqy mariadb-server aspnetcore-runtime-2.2

# Confirgure MariaDB
RUN set -ex; sed -ri 's/^user\s/#&/' /etc/mysql/my.cnf /etc/mysql/conf.d/*; \
        rm -rf /var/lib/mysql; \
        mkdir -p /var/lib/mysql /var/run/mysqld /etc/mysql/docker.conf.d /docker-entrypoint-initdb.d; \
        chown -R mysql:mysql /var/lib/mysql /var/run/mysqld /etc/mysql; \
        chmod 777 /var/run/mysqld; \
        find /etc/mysql/ -name '*.cnf' -print0 \
		| xargs -0 grep -lZE '^(bind-address|log)' \
		| xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/'; \
        echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf
RUN set -ex; echo "!includedir /etc/mysql/docker.conf.d"

## Clean-up
RUN set -ex; rm -rf /var/lib/apt/lists/*
RUN set -ex; apt-get -y autoremove
RUN set -ex; apt-get -y clean

## Start
VOLUME /var/lib/mysql /docker-entrypoint-initdb.d /etc/mysql/docker.conf.d/