#!/bin/bash
set -e
set -x

SHORT_HOSTNAME=$(hostname -s)
DATABASE_NODE="db${SHORT_HOSTNAME:(-1)}.$(hostname -d)"
DB_CONNECTION=${DB_CONNECTION:-$DATABASE_NODE}
DB_NAME=${DB_NAME:-icingaweb2}
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-123}
DB_ICINGAWEB_USER=${DB_ICINGA_USER:-icingaweb2}
DB_ICINGAWEB_PASSWORD=${DB_ICINGA_PASSWORD:-icinga123}
DB_ICINGAWEB_PASSWORD_HASH=${DB_ICINGAWEB_PASSWORD_HASH:-'$1$Ukm2HiY.$Fr6DFZIo3ok5L05/xZA7p0'}

DIR_CONFIG_APACHE=${DIR_CONFIG_APACHE:-/etc/apache2}
EXTERNAL_DIR_CONFIG_APACHE=${EXTERNAL_DIR_CONFIG_APACHE:-/dir-config/apache2}
DIR_CONFIG=${DIR_CONFIG:-/etc/icingaweb2}
EXTERNAL_DIR_CONFIG=${EXTERNAL_DIR_CONFIG:-/dir-config/icingaweb2}

#In  general,  apache2  should  not  be  invoked directly, but rather should be invoked via
#/etc/init.d/apache2 or apache2ctl. The default Debian configuration  requires  environment
#variables  that	are  defined  in /etc/apache2/envvars and are not available if apache2 is
#started directly.  However, apache2ctl can be used to pass arbitrary arguments to apache2.

#environment variables in
source /etc/apache2/envvars

#ICINGA@ part

initfile="/app/first-run-done";
# check if this is first container run
if [ ! -f "${initfile}" ]; then
    echo "first start running";

    #echo "For security reason, you would require to generate the token and paste it on the first step of the wizard."
    #icingacli setup token create

    # https://www.icinga.com/docs/icingaweb2/latest/doc/20-Advanced-Topics/#web-setup-automation
    #Set a timezone in php.ini configuration file.
    echo "timezone set to Europe/Bratislava"
    sed -i -- 's|;date.timezone =|date.timezone = "Europe/Bratislava"|' /etc/php/7.0/apache2/php.ini

    #Create a database for Icinga Web 2, i.e. icingaweb2.
    if ! mysqlshow -h ${DB_CONNECTION} -u root -p${DB_ROOT_PASSWORD} ${DB_NAME}; then
        echo "creating new database in mysql";
        mysql -h ${DB_CONNECTION} -u root -p${DB_ROOT_PASSWORD} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};";
        #Import the database schema
        mysql -h ${DB_CONNECTION} -u root -p${DB_ROOT_PASSWORD} -D ${DB_NAME} < /usr/share/icingaweb2/etc/schema/mysql.schema.sql;
    fi;
    #Insert administrator user in the icingaweb2 access database
    # if database exists or not the situation can be without user
    SQL="grant all privileges on ${DB_NAME}.* to '${DB_ICINGAWEB_USER}'@'$(hostname)' identified by '${DB_ICINGAWEB_PASSWORD}';"
    mysql -h ${DB_CONNECTION} -u root -p${DB_ROOT_PASSWORD} -e "${SQL}";

    # and in this database the user or group for accessing the web will be created IF NOT EXISTS
    SQL="SELECT 1 FROM icingaweb_user WHERE name = 'admin';"
    OUTPUT=$(mysql -h ${DB_CONNECTION} -u${DB_ICINGAWEB_USER} -p${DB_ICINGAWEB_PASSWORD} -D ${DB_NAME} -e "${SQL}" -NB;)
    if [ "$OUTPUT" != "1" ]; then
      #create this user echo "ok"
      SQL="INSERT INTO icingaweb_user (name, active, password_hash, ctime) VALUES ('admin', 1, '${DB_ICINGAWEB_PASSWORD_HASH}', CURRENT_TIMESTAMP);
      INSERT INTO icingaweb_group (name, ctime) VALUES ('administrators', CURRENT_TIMESTAMP );";
      mysql -h ${DB_CONNECTION} -u ${DB_ICINGAWEB_USER} -p${DB_ICINGAWEB_PASSWORD} -D ${DB_NAME} -e "${SQL}";

      #get the group_id of created group and finaly create the user
      SQL="SELECT id FROM icingaweb_group WHERE name = 'administrators';";
      WEBGROUP_ID=$(mysql -h ${DB_CONNECTION} -u ${DB_ICINGAWEB_USER} -p${DB_ICINGAWEB_PASSWORD} -D ${DB_NAME} -BN -e "${SQL}");
      SQL="INSERT INTO icingaweb_group_membership (group_id, username, ctime) VALUES (${WEBGROUP_ID}, 'admin', CURRENT_TIMESTAMP);";
      mysql -h ${DB_CONNECTION} -u ${DB_ICINGAWEB_USER} -p${DB_ICINGAWEB_PASSWORD} -D ${DB_NAME} -e "${SQL}";
    fi;

    #Make sure the ido-mysql and api features are enabled in Icinga 2: these have to be done in icinga2 container
    #icinga2 feature enable ido-mysql;
    #icinga2 feature enable api;

    #Generate Apache/nginx config. This command will print an apache config for you on stdout > and place it:
    icingacli setup config webserver apache > /etc/apache2/sites-enabled/icingaweb2.conf

    #Add www-data user to icingaweb2 group if not done already
    addgroup --system icingaweb2
    usermod -a -G icingaweb2 www-data

    #Create the Icinga Web 2 configuration in /etc/icingaweb2.
    # The directory can be easily created with:
    #This command ensures that the directory has the appropriate ownership and permissions.
    icingacli setup config directory

    cp -r /app/configs/icingaweb2-cnf-files/* /etc/icingaweb2/

    ln -s /usr/share/icingaweb2/modules/monitoring /etc/icingaweb2/enabledModules/monitoring

    chown -R root:icingaweb2 /etc/icingaweb2
    find /etc/icingaweb2 -type f -exec chmod u+rw,g+rw,o-rw {} +


#    #if there is external config file provided in dir-config
#    if [ -f /dir-config/icingaweb2/config.ini ]; then
#        echo "external config provided - link will be created";
#        rm -r /etc/icingaweb2;
#        ln -s /dir-config/icingaweb2 /etc/icingaweb2;
#    else
#        echo "internal config will be moved to /dir-config"
#        cp -r /etc/icingaweb2/* /dir-config/icingaweb2;
#        rm -r /etc/icingaweb2;
#        ln -s /dir-config/icingaweb2 /etc/icingaweb2;
#    fi;


    ### USAGE RULES applied: on ICINGAWEB2 config files ###
    #first start shoud be with basic config
    #1. installed config files replaced by those provided by docker file structure already in Dockerfile at the end
    #2. if config files provided externally use them
    # if [ -z "$(ls -A /etc)" ]; then      echo "Empty"; else echo "Files"; fi
    if [ -z "$(ls -A ${EXTERNAL_DIR_CONFIG})" ]; then
        echo "${EXTERNAL_DIR_CONFIG} is Empty config files will be used from image itself";
        ### USAGE RULE for config files applied
        #only backup
        cp -r ${DIR_CONFIG}/* /app/etc_icingaweb2_config_backup;
        # now applied
        rm -r ${DIR_CONFIG}/*;
        cp -r /app/configs/icinga2-cnf-files/* ${DIR_CONFIG}/;
    else
        echo "${EXTERNAL_DIR_CONFIG} is with files so mysqld will use them and link will be created";
        rm -r ${DIR_CONFIG}
        ln -s ${EXTERNAL_DIR_CONFIG} ${DIR_CONFIG};
    fi

    #in both cases the owner has to be chnaged to ensure work with files
    chown -R root:icingaweb2 /dir-config/icingaweb2
    find /dir-config/icingaweb2 -type d -exec chmod 2770 {} +

    #enable monitoring module monitoring -> /usr/share/icingaweb2/modules/monitoring
    ln -s /usr/share/icingaweb2/modules/monitoring /dir-config/icingaweb2/enabledModules/monitoring;

    ### USAGE RULES applied: on APACHE config files ###
    #1. installed config files replaced by those provided by docker file structure already in Dockerfile at the end
    #2. if config files provide externally use them
    # test only for file apache2.conf
    if [ ! -f "${EXTERNAL_DIR_CONFIG_APACHE}/apache2.conf" ]; then
        echo "${EXTERNAL_DIR_CONFIG_APACHE} is Empty config files will be used from image itself";
        ### USAGE RULE for config files applied
        #only backup
        mkdir /app/etc_apache2_config_backup;
        cp ${DIR_CONFIG_APACHE}/apache2.conf /app/etc_apache2_config_backup/;
        # now applied
        rm ${DIR_CONFIG_APACHE}/apache2.conf;
        cp /app/configs/apache2-cnf-files/apache2.conf ${DIR_CONFIG_APACHE}/apache2.conf;
    else
        echo "${EXTERNAL_DIR_CONFIG_APACHE} is with apache2.conf and apache will use this and link will be created";
        #only backup
        mkdir /app/etc_apache2_config_backup;
        cp ${DIR_CONFIG_APACHE}/apache2.conf /app/etc_apache2_config_backup/;
        # now applied
        rm ${DIR_CONFIG_APACHE}/apache2.conf;
        ln -s ${EXTERNAL_DIR_CONFIG_APACHE}/apache2.conf ${DIR_CONFIG_APACHE}/apache2.conf;
    fi;

    touch ${initfile};
    echo "first start finished";
fi;

#and apache2ctl with config file and foreground
exec "$@"
