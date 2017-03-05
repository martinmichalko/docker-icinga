
## cluster
### start the first node of the cluster

```bash
docker run --name mariadb-node1 --network host \
-v /dir-config/mariadb:/etc/mysql/conf.d:ro \
-v /dir-data/mariadb:/var/lib/mysql:rw \
 node1.mariadb.mate.solutions:5000/mariadb mysqld --wsrep-new-cluster
```

### start the rest nodes:
both of course with the correct galera config

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

### single node without external volumes - testing

```bash
docker run -d --name mariadb-node2 --network host \
  node1.mariadb.mate.solutions:5000/mariadb mysqld

docker run -d --name mariadb-node1 --network host  localhost:5000/mariadb mysqld
```
