FROM debian:jessie
MAINTAINER Martin Michalko (matemichal@gmail.com)

###ICINGA WEB2
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added

#COMMON
# add common repositories
COPY configs/sources.list /etc/apt/sources.list
# set http_proxy for apt
COPY configs/apt-conf-d-00proxy /etc/apt/apt.conf.d/00proxy

#get repo key
COPY configs/debmon.repo.key /app/configs/debmon.repo.key
# and also add repositories for httpredir and debmon
COPY configs/sources.debmon.list /etc/apt/sources.list.d/sources.debmon.list

#add new apt key
RUN apt-key add /app/configs/debmon.repo.key

RUN apt-get update && apt-get -y upgrade

# packages installation
RUN apt-get -y install apache2 apache2-doc apache2-utils
RUN apt-get -y install libapache2-mod-python
RUN apt-get -y install php5

RUN apt-get -y install icingaweb2

### external volumes possible - only config data is database
#whole config directory:
VOLUME /dir-config/

#named pipe located at "/var/run/icinga2/cmd/icinga2.cmd" to send commands
#between icinga2 and icingaweb2:
VOLUME /var/run/icinga2/cmd/

## copy startup scripts and configuration files
COPY scripts /app/
COPY configs /app/configs

# Define workdir - not needed
WORKDIR /app
RUN chmod u+x /app/*

ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["/usr/sbin/apache2", "-f", "/etc/apache2/apache2.conf", "-DFOREGROUND"]
