FROM debian:stretch
MAINTAINER Martin Michalko (matemichal@gmail.com)

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql -g 2006 && useradd -r -g mysql mysql -u 2006

# add repositories
COPY configs/sources.list /etc/apt/sources.list
# set http_proxy for apt
COPY configs/apt-conf-d-00proxy /etc/apt/apt.conf.d/00proxy

RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install gnupg2 software-properties-common dirmngr

RUN apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xF1656F24C74CD1D8
COPY configs/sources.mariadb.list /etc/apt/sources.list.d/sources.mariadb.list
RUN apt-get update
# packages installation
COPY configs/debconf.txt /app/configs/debconf.txt
RUN debconf-set-selections /app/configs/debconf.txt
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y rsync galera-3 mariadb-server

# cleanup
RUN rm -r /var/lib/mysql

# external volumes possible
# whole config directory:
# default directory /etc/mysql/conf.d
VOLUME /dir-config/

#data directory:
#together with the file to Identify the node with the most advanced node state ID. /var/lib/mysql/grastate.dat
#default directory /var/lib/mysql
VOLUME /dir-data/

## copy startup scripts and configuration files
COPY scripts /app/
COPY configs /app/configs

# Define workdir
WORKDIR /app
RUN chmod u+x /app/*

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["mysqld"]
