#!/bin/bash
set -e
set -x

# define variable defaults
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-123}
DIR_CONFIG=${DIR_CONFIG:-/etc/mysql}
CONFIG_FILE=${CONFIG_FILE:-/etc/mysql/my.cnf}
DIR_DATA=${DIR_DATA:-/var/lib/mysql}
EXTERNAL_DIR_CONFIG=${EXTERNAL_DIR_CONFIG:-/dir-config}
EXTERNAL_DIR_DATA=${EXTERNAL_DIR_DATA:-/dir-data}

function wait_for_db {
    mysql=( mysql --protocol=socket -uroot -hlocalhost --socket=/var/run/mysqld/mysqld.sock );
    for i in {30..0}; do
        if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
    				break;
    		fi
    		  	echo 'MySQL init process in progress...';
    			  sleep 1;
    done
    if [ "$i" = 0 ]; then
        echo >&2 'MySQL init process failed.';
    		exit 1;
    fi
}

initfile="/app/first-run-done";
# check if this is first container run
if [ ! -f "${initfile}" ]; then
    echo "first start running";

    ### USAGE RULES applied: data files
    #symbolic link between /dir-data and /var/lib/mysql will be created i every case during first start
    chown -R mysql:mysql ${EXTERNAL_DIR_DATA};
    ln -s ${EXTERNAL_DIR_DATA} ${DIR_DATA};
    #we already have the symbolic link

    if [ -z "$(ls -A ${EXTERNAL_DIR_DATA})" ]; then
        echo "${EXTERNAL_DIR_DATA} is Empty and will be filled with new database"

        mysql_install_db --datadir="${DIR_DATA}" --user=mysql

        mysqld --user=mysql --skip-networking --datadir="${DIR_DATA}" --socket=/var/run/mysqld/mysqld.sock &

        wait_for_db

        mysql --protocol=socket -uroot -hlocalhost --socket=/var/run/mysqld/mysqld.sock <<-EOSQL
                DELETE FROM mysql.user;
                CREATE USER 'root'@'%' IDENTIFIED BY "${DB_ROOT_PASSWORD}";
                GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
                DROP DATABASE IF EXISTS test;
                FLUSH PRIVILEGES;
EOSQL

        mysqladmin -u root -p"${DB_ROOT_PASSWORD}" shutdown;

    else
      echo "external data provided and they will not be changed";
    fi;

    ### USAGE RULES applied: config files ###
    #first start shoulb be with basic config - no cluster - already provided
    #1. installed config files replaced by those provided by docker file structure already in Dockerfile at the end
    #2. if config files provide externally use them
    # if [ -z "$(ls -A /etc)" ]; then      echo "Empty"; else echo "Files"; fi
    if [ -z "$(ls -A ${EXTERNAL_DIR_CONFIG})" ]; then
        echo "${EXTERNAL_DIR_CONFIG} is Empty config files will be used from image itself";
        ### USAGE RULE for config files applied
        #only backup
        cp -r /etc/mysql /app/etc_mysql_config_backup;
        # now applied
        rm -r /etc/mysql/*;
        cp -r /app/configs/mariadb-cnf-files/* /etc/mysql/;
    else
        echo "${EXTERNAL_DIR_CONFIG} is with files so mysqld will use them and link will be created";
        rm -r ${DIR_CONFIG}
        ln -s ${EXTERNAL_DIR_CONFIG} ${DIR_CONFIG};
    fi

    touch ${initfile};
    echo "first start finished";
fi;

echo "$@"
exec "$@"
