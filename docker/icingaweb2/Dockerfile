FROM debian:stretch
MAINTAINER Martin Michalko (matemichal@gmail.com)

###ICINGA WEB2
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added

#COMMON
# add common repositories
COPY configs/sources.list /etc/apt/sources.list
# set http_proxy for apt
COPY configs/apt-conf-d-00proxy /etc/apt/apt.conf.d/00proxy

RUN apt-get update && apt-get -y upgrade
RUN apt-get -y install gnupg2

#get repo key #add new apt key
COPY configs/icinga.key /app/configs/icinga.key
RUN apt-key add /app/configs/icinga.key

# and also add repositories for httpredir and debmon
COPY configs/sources.icinga.list /etc/apt/sources.list.d/sources.icinga.list

# packages installation
RUN apt-get -y install apache2 apache2-doc apache2-utils
RUN apt-get -y install libapache2-mod-python
RUN apt-get -y install php5.6

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
