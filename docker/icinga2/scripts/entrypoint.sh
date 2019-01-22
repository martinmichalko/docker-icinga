#!/bin/bash
# icinga2
set -e
set -x

SHORT_HOSTNAME=$(hostname -s)
DATABASE_NODE="db${SHORT_HOSTNAME:(-1)}.$(hostname -d)"
GROUP_NAME=$(hostname)
PROVIDER=${GROUP_NAME::3}1.$(hostname -d)
MASTER_PROVIDER=${MASTER_PROVIDER:-$PROVIDER}

#entrypoint - ICINGA2

DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-123}
DB_ICINGA_USER=${DB_ICINGA_USER:-icinga2}
DB_ICINGA_PASSWORD=${DB_ICINGA_PASSWORD:-icinga123}
DB=${DB:-$DATABASE_NODE}

PKI_TICKET=${PKI_TICKET:-}
CONFIG_FILE=${CONFIG_FILE:-/etc/icinga2/icinga2.conf}

DIR_CONFIG=${DIR_CONFIG:-/etc/icinga2}
EXTERNAL_DIR_CONFIG=${EXTERNAL_DIR_CONFIG:-/dir-config}

DIR_CA=${DIR_CA:-/var/lib/icinga2/ca}
EXTERNAL_DIR_CA=${EXTERNAL_DIR_CA:-/dir-config/icinga2-ca}

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
    chown -R nagios:www-data /var/run/icinga2;
    ### USAGE RULES applied: config files ###
    #first start shoulb be with basic config - no cluster - already provided
    #1. installed config files replaced by those provided by docker file structure already in Dockerfile at the end
    #2. if config files provide externally use them
    # if [ -z "$(ls -A /etc)" ]; then      echo "Empty"; else echo "Files"; fi
    if [ -z "$(ls -A ${EXTERNAL_DIR_CONFIG})" ]; then
        echo "${EXTERNAL_DIR_CONFIG} is Empty config files will be prepared all for the first usage from the image";
        ### USAGE RULE for config files applied

        cp -r ${DIR_CONFIG}/* ${EXTERNAL_DIR_CONFIG}/;
        # now applied
        rm -r ${DIR_CONFIG};
        ln -s ${EXTERNAL_DIR_CONFIG} ${DIR_CONFIG};

        if [ "${SHORT_HOSTNAME:(-1)}" -eq "1" ]; then
            echo "activating MASTER and mysql feature";
            icinga2 node setup --master;
        else
            echo "activating client node with HA features";
            mkdir -p /var/lib/icinga2/certs
            cp /var/lib/icinga2/ca/ca.crt /var/lib/icinga2/certs/

            icinga2 node setup --cn $(hostname) --zone $(hostname) \
            --ticket ${PKI_TICKET} --endpoint ${MASTER_PROVIDER} \
            --trustedcert /var/lib/icinga2/ca/ca.crt \
            --accept-commands --accept-config
        fi;
        #change the localhost to $DB in file features-enabled/ido-mysql.conf
        # All instances within the same zone (e.g. the master zone as HA cluster)
        # must have the DB IDO feature enabled.
        #https://icinga.com/docs/icinga2/latest/doc/06-distributed-monitoring/#distributed-monitoring-high-availability-features
        sed -i -- "s|localhost|$DB|" /etc/icinga2/features-available/ido-mysql.conf;
        #all instances have to enable checker notification and ido mysql and
        #they will dynamically work with ido connection
        icinga2 feature enable checker;
        icinga2 feature enable notification;
        icinga2 feature enable ido-mysql;
    else
        echo "${EXTERNAL_DIR_CONFIG} is with files so container will use them and link will be created";
        rm -r ${DIR_CONFIG}
        ln -s ${EXTERNAL_DIR_CONFIG} ${DIR_CONFIG};
    fi;

    # set the right owner at the end of configuration
    chown -R nagios:nagios /etc/icinga2
    chown -R nagios:nagios /dir-config
    chown -R nagios:nagios /var/lib/icinga2
    chown -R nagios:www-data /var/run/icinga2

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
