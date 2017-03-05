FROM debian:jessie
MAINTAINER Martin Michalko (matemichal@gmail.com)

###ICINGA2
# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added

#COMMON
# add common repositories
COPY configs/sources.list /etc/apt/sources.list
# set http_proxy for apt
COPY configs/apt-conf-d-00proxy /etc/apt/apt.conf.d/00proxy

RUN apt-get update && apt-get -y upgrade

#RUN  apt-get -y install wget
#RUN wget -O - http://debmon.org/debmon/repo.key 2>/dev/null | apt-key add -
#alternative approach
COPY configs/debmon.repo.key /app/configs/debmon.repo.key
RUN apt-key add /app/configs/debmon.repo.key

# and also httpredir and debmon icinga2 and icingaweb2 both
COPY configs/sources.debmon.list /etc/apt/sources.list.d/sources.debmon.list

RUN apt-get update

# packages installation
COPY configs/debconf.txt /app/configs/debconf.txt
RUN debconf-set-selections /app/configs/debconf.txt
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install icinga2 icinga2-ido-mysql

### external volumes possible - only config data is database
#whole config directory:
VOLUME  /etc/icinga2/

#named pipe located at "/var/run/icinga2/cmd/icinga2.cmd" to send commands
VOLUME /var/run/icinga2/cmd/

#data volume is replaced by database

## copy startup scripts and configuration files
COPY scripts /app/
COPY configs /app/configs

# Define workdir
WORKDIR /app
RUN chmod u+x /app/*

ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["icinga2", "daemon"]
