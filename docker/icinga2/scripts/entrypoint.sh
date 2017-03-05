#!/bin/bash
set -x

#entrypoint - ICINGA2
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-123}
DB_ICINGA_USER=${DB_ICINGA_USER:-icinga2}
DB_ICINGA_PASSWORD=${DB_ICINGA_PASSWORD:-icinga123}


initfile="/app/first-run-done";
# check if this is first container run
if [ ! -f "${initfile}" ]; then
    echo "first start running";
    # PREPARE DATABASE icinga2 if it does not exist
    mysqlshow -h 127.0.0.1 -u root -p$DB_ROOT_PASSWORD icinga2;
    # -ne means not equal
    if [ $? -ne 0 ]; then
        echo "creating new database in mysql";
        mysql -h 127.0.0.1 -u root -p$DB_ROOT_PASSWORD -e 'CREATE DATABASE IF NOT EXISTS icinga2;';
        mysql -h 127.0.0.1 -u root -p$DB_ROOT_PASSWORD -e "grant all privileges on icinga2.* to icinga2@localhost identified by 'icinga123';";
        mysql -h 127.0.0.1 -u $DB_ICINGA_USER -p$DB_ICINGA_PASSWORD -D icinga2 < /usr/share/icinga2-ido-mysql/schema/mysql.sql;
    fi;

    set -e
    usermod -a -G nagios www-data;

    #if directory /run/icinga2 does not exist create it with rights nagios:www-data
    chown -R nagios:www-data /run/icinga2;
    echo "activating command and mysql feature";
    icinga2 feature enable ido-mysql command
    echo "activated command and mysql feature";
    #change the localhost to 127.0.0.1 in file features-enabled/ido-mysql.conf
    sed -i -- 's|localhost|127.0.0.1|' /etc/icinga2/features-enabled/ido-mysql.conf
    echo "icinga2 stopped";
    touch ${initfile};
    echo "first start finished";
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
