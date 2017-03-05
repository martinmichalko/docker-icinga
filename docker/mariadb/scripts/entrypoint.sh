#!/bin/bash
set -e
set -x

# define variable defaults
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-123}
CONFIG_FILE=${CONFIG_FILE:-/etc/mysql/my.cnf}
DIR_DATA=${DIR_DATA:-/var/lib/mysql}

wait_for_db() {
    echo " wait for database to come up ..."
    while ! mysqladmin ping -h"127.0.0.1" --silent; do
        sleep 1
    done
}


echo "$@"

if [ -f /dir-config/my.cnf ]; then
    echo "external config provided";
    CONFIG_FILE="/dir-config/my.cnf";
fi;

if [ -d /dir-data/mysql ]; then
    DIR_DATA="/dir-data";
fi;

if [ ! -d $DIR_DATA/mysql ]; then
    mysql_install_db --user=mysql

    #One problem with starting the MySQL server daemon directly is that if it crashes,
    #you may not be aware of it until a user complains. To be assured of the daemon being
    #restarted automatically, use the mysqld_safe script.
    mysqld_safe --no-defaults --bind-address=127.0.0.1 &

    wait_for_db

    mysql --protocol=socket -uroot <<-EOSQL
            DELETE FROM mysql.user;
            CREATE USER 'root'@'%' IDENTIFIED BY '$DB_ROOT_PASSWORD';
            GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION;
            DROP DATABASE IF EXISTS test;
            FLUSH PRIVILEGES;
EOSQL

    mysqladmin -u root -p$DB_ROOT_PASSWORD shutdown
fi

#Global Options for maysqld
#--defaults-file=# 	Only read default options from the given file #.
PARAMETERS="$@"
if [ "$PARAMETERS" == "mysqld" ]; then
    set -- "mysqld" "--defaults-file=$CONFIG_FILE" "--datadir=$DIR_DATA";
fi
if [ "$PARAMETERS" == "mysqld --wsrep-new-cluster" ]; then
    set -- "mysqld" "--defaults-file=$CONFIG_FILE" "--datadir=$DIR_DATA" "--wsrep-new-cluster";
fi

echo "$@"
exec "$@"
