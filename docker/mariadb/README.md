## Mariadb start and usage

Database can be prepared by started container for the first time only - if not provided in external directory..

mysqld  Ver 10.3.9-MariaDB-1:10.3.9
Default options are read from the following files in the given order: /etc/my.cnf /etc/mysql/my.cnf ~/.my.cnf
--print-defaults          Print the program argument list and exit.
--no-defaults             Don't read default options from any option file.
The following specify which files/extra groups are read (specified before remaining options):
--defaults-file=#         Only read default options from the given file #.
--defaults-extra-file=#   Read this file after the global files are read.
--defaults-group-suffix=# Additionally read default groups with # appended as a suffix.

--datadir

## Cluster
### Start the first node of the cluster

```bash
docker run --name mariadb-db3 --network host \
-v /dir-config/mariadb:/dir-config:ro \
-v /dir-data/mariadb:/dir-data:rw \
registry.icinga2.mate.solutions:5000/mariadb mysqld --wsrep-new-cluster
```

### Start the rest nodes:
of course with the correct galera config

```bash
docker run --name mariadb-db1 --network host \
-v /dir-config/mariadb:/dir-config:ro \
-v /dir-data/mariadb:/dir-data:rw \
 registry.icinga2.mate.solutions:5000/mariadb mysqld

docker run --name mariadb-db2 --network host \
-v /dir-config/mariadb:/dir-config:ro \
-v /dir-data/mariadb:/dir-data:rw \
 registry.icinga2.mate.solutions:5000/mariadb mysqld
```

### Single node without external volumes - testing

argument "--rm" ensures to delete the container  after stop automatically  

```bash
docker run --rm --name mariadb-db1 --network host registry.icinga2.mate.solutions:5000/mariadb mysqld --wsrep-new-cluster

docker run -ti --entrypoint=/bin/bash --rm --name mariadb-db1 --network host registry.icinga2.mate.solutions:5000/mariadb

docker run --rm -d --name mariadb-db1 --network host -v /dir-config/mariadb:/dir-config:ro -v /dir-data/mariadb:/dir-data:rw registry.icinga2.mate.solutions:5000/mariadb mysqld

docker run --rm -ti --name mariadb-db1 --network host -v /dir-config/mariadb:/dir-config:ro -v /dir-data/mariadb:/dir-data:rw --entrypoint=/bin/bash registry.icinga2.mate.solutions:5000/mariadb

docker run --rm -d --name mariadb-db1 --network host  registry.icinga2.mate.solutions:5000/mariadb mysqld
```
