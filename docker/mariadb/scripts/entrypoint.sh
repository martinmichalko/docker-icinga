#!/bin/bash
set -e
set -x

# define variable defaults
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-123}
CONFIG_FILE=${CONFIG_FILE:-/etc/mysql/my.cnf}
DIR_DATA=${DIR_DATA:-/var/lib/mysql}

function wait_for_db {
    mysql=( mysql --protocol=socket -uroot -p$DB_ROOT_PASSWORD -hlocalhost --socket=/var/run/mysqld/mysqld.sock )
    for i in {30..0}; do
        if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
    				break
    		fi
    		  	echo 'MySQL init process in progress...'
    			  sleep 1
    done
    if [ "$i" = 0 ]; then
        echo >&2 'MySQL init process failed.'
    		exit 1
    fi
}

initfile="/app/first-run-done";
# check if this is first container run
if [ ! -f "${initfile}" ]; then
    echo "first start running";

    #symbolic link between /dir-data and /var/lib/mysql will be created i every case during first start
    ln -s /dir-data /var/lib/mysql
    chown -R mysql:mysql /dir-data
    if [ -d /dir-data/mysql ]; then
        echo "external data provided";
    else
        mysql_install_db --datadir="${DIR_DATA}" --user=mysql

        mysqld --skip-networking --datadir="${DIR_DATA}" --socket=/var/run/mysqld/mysqld.sock &

        wait_for_db

        mysql --protocol=socket -uroot -hlocalhost --socket=/var/run/mysqld/mysqld.sock <<-EOSQL
                DELETE FROM mysql.user;
                CREATE USER 'root'@'%' IDENTIFIED BY "{$DB_ROOT_PASSWORD}";
                GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
                DROP DATABASE IF EXISTS test;
                FLUSH PRIVILEGES;
EOSQL

        mysqladmin -u root -p${DB_ROOT_PASSWORD} shutdown;
    fi;

    # prepare config as config external has to be made as last step
    #first should be defauld atabase activated with default config
    if [ -f /dir-config/my.cnf ]; then
        echo "external config provided";
        rm -rf /etc/mysql;
        ln -s /dir-config /etc/mysql;
    fi;

    touch ${initfile};
    echo "first start finished";
fi;

echo "$@"
exec "$@"
