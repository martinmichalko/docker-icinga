### 3 nodes with mariadb cluster and icinga2 in separated docker containers

(working on Debian Jessie only)

- docker directory - includes Dockerfiles for
  - mariadb - Mariadb sql database prepared for cluster usage
  - icinga2 - Container for icinga2 daemon
  - icingaweb2 - Container includes the apache web server, php and icingaweb2 service written to manage the icinga2 services.

  Icinga2 and icingaweb2 are in separated containers not only because the basic purpose of docker is one service per docker (docker-icingaweb2 runs web server) but also that for company usage is better to deploy the standardized containers of each type (including web).  

  For application deployment is also possible the approach to pack each php application in separate container. In case that this is application prepared by third party distributed in .deb packages is not simple to identify which files are application's and which belongs to php install.

  Own made applications can be packed in their own containers without any problems.

- roles directory - there are role definitions for ansible playbooks to build the environment on three nodes

how to get info about number of nodes in galera cluster:

```bash
mysql -h 127.0.0.1 -u root -p123 -e 'SELECT VARIABLE_VALUE as "cluster size" FROM INFORMATION_SCHEMA.GLOBAL_STATUS WHERE VARIABLE_NAME="wsrep_cluster_size"'
```

More detailed info are in README files in nested directories.
