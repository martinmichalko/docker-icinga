#!/bin/bash
set -e
set -x

# define variable defaults
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD:-123}

wait_for_db() {
    echo " wait for database to come up ..."
    while ! mysqladmin ping -h"127.0.0.1" --silent; do
        sleep 1
    done
}


echo "$@"

if [ ! -d /var/lib/mysql/mysql ]; then
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

exec "$@"
