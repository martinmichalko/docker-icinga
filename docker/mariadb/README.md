## Directories
/etc/mysql/conf.d is local directory for custom configuration files.
/var/lib/mysql is local directory for database

These config and data files can be provided for the docker container as external volumes.

I all three containers is used the same approach
/dir-config is directory for external config files
/dir-data is directory for external data files

Database can be prepared by started container for the first time only - if not provided in external directory..

## Cluster
### Start the first node of the cluster

```bash
docker run --name mariadb-node1 --network host \
-v /dir-config/mariadb:/etc/mysql/conf.d:ro \
-v /dir-data/mariadb:/var/lib/mysql:rw \
 node1.mariadb.mate.solutions:5000/mariadb mysqld --wsrep-new-cluster
```

### Start the rest nodes:
of course with the correct galera config

```bash
docker run --name mariadb-node2 --network host \
-v /dir-config/mariadb:/etc/mysql/conf.d:ro \
-v /dir-data/mariadb:/var/lib/mysql:rw \
 node1.mariadb.mate.solutions:5000/mariadb mysqld

docker run --name mariadb-node3 --network host \
-v /dir-config/mariadb:/etc/mysql/conf.d:ro \
-v /dir-data/mariadb:/var/lib/mysql:rw \
 node1.mariadb.mate.solutions:5000/mariadb mysqld
```

### Single node without external volumes - testing

argument "--rm" ensures to delete the container  after stop automatically  

```bash
docker run --rm -d --name mariadb-node2 --network host \
  node1.mariadb.mate.solutions:5000/mariadb mysqld

docker run --rm -d --name mariadb-node1 --network host  localhost:5000/mariadb mysqld
```
