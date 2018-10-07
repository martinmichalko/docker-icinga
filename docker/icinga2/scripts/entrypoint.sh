#!/bin/bash
set -e
set -x

SHORT_HOSTNAME=$(hostname -s)
DATABASE_NODE="db${SHORT_HOSTNAME:(-1)}.$(hostname -d)"

#entrypoint - ICINGA2
CONFIG_FILE=${CONFIG_FILE:-/etc/icinga2/icinga2.conf}
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-123}
DB_ICINGA_USER=${DB_ICINGA_USER:-icinga2}
DB_ICINGA_PASSWORD=${DB_ICINGA_PASSWORD:-icinga123}
DB=${DB:-$DATABASE_NODE}

initfile="/app/first-run-done";
# check if this is first container run
if [ ! -f "${initfile}" ]; then
    echo "first start running";
    # PREPARE DATABASE icinga2 if it does not exist
    if ! mysqlshow -h ${DB} -u root -p${DB_ROOT_PASSWORD} icinga2; then
        echo "creating new database in mysql";
        mysql -h ${DB} -u root -p${DB_ROOT_PASSWORD} -e 'CREATE DATABASE IF NOT EXISTS icinga2;';
        mysql -h ${DB} -u root -p${DB_ROOT_PASSWORD} -e "grant all privileges on icinga2.* to icinga2@$(hostname) identified by 'icinga123';";
        mysql -h ${DB} -u ${DB_ICINGA_USER} -p${DB_ICINGA_PASSWORD} -D icinga2 < /usr/share/icinga2-ido-mysql/schema/mysql.sql;
    else
        mysql -h ${DB} -u root -p${DB_ROOT_PASSWORD} -e "grant all privileges on icinga2.* to icinga2@$(hostname) identified by 'icinga123';";
    fi;

    set -e
    usermod -a -G nagios www-data;

    #if directory /run/icinga2 does not exist create it with rights nagios:www-data

    chown -R nagios:www-data /run/icinga2;

    #if there is external config file provided in dir-config
    if [ -f /dir-config/icinga2.conf ]; then
        echo "external config provided - link will be created";
        rm -r /etc/icinga2;
        ln -s /dir-config /etc/icinga2;
    else
        cp -r /etc/icinga2/* /dir-config;
        rm -r /etc/icinga2;
        ln -s /dir-config /etc/icinga2;
        echo "activating command and mysql feature";
        icinga2 feature enable ido-mysql command
        echo "activated command and mysql feature";
        #change the localhost to $DB in file features-enabled/ido-mysql.conf
        sed -i -- "s|localhost|$DB|" /etc/icinga2/features-enabled/ido-mysql.conf;
    fi;
    #in both cases the owner has to be chnaged to ensure work with files
    chown -R nagios:nagios /dir-config
    chown -R icinga2:icinga2 /var/lib/icinga2/certs
    Dlzka
    icinga2 node setup --master

    touch ${initfile};
    echo "first start finished";

    set -- "$@" "-c" "${CONFIG_FILE}"
fi;

exec "$@";
#from dockerfile
#CMD ["icinga2", "daemon"]
### Help
#-c, --config arg
#    Using this option you can specify one or more configuration files.
#    Config files are processed in the order they are specified on the command-line.
#    When no configuration file is specified and the --no-config is not used,
#    Icinga 2 automatically falls back to using the configuration file
#    SysconfDir + /icinga2/icinga2.conf (where SysconfDir is usually /etc).
#
#-e, --errorlog arg
#    Log fatal errors to the specified log file (only works in combination with --daemonize).
#-d, --daemonize
#    Detach from the controlling terminal.
