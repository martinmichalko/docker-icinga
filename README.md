## 3 nodes with mariadb cluster and icinga2 in separated docker containers

### Basics

Tool to create test environment with icinga nodes with mariadb cluster as backend database.

### Features

* docker directory - includes Dockerfiles for
  - mariadb - database prepared for cluster usage
  - icinga2 - Container for icinga2 daemon
  - icingaweb2 - Container includes the apache web server, php and icingaweb2 service written to manage the icinga2 services.

Icinga2 and icingaweb2 are in separated containers to deploy the standardized containers of each application type (including web).  

For application deployment is also possible the approach to pack each php application in separate container. In case that this is application prepared by third party distributed in .deb packages is not simple to identify which files are application's and which belongs to php install.

Own made applications can be packed in their own containers without any problems.

### Commands to prepare mariadb cluster and single icinga2 and icingaweb2

You need also playbooks from my previous ansible-testing environment project https://github.com/martinmichalko/ansible-testing_environment

Separate your own file of test environment variables `group_vars/test-env-all.yml` change them for new project and create whole environment with working directory testing environment with command:

```bash
ansible-playbook -i {{ path to docker-icinga files }}/inventory create-update-config.yml --extra-vars "@{{ path to docker-icinga files }}//group_vars/test-env-all.yml"
```

Prepare for python3:
```bash
ansible-playbook -i inventory packages-req.yml
```
Equip all nodes with specific packages:
```bash
ansible-playbook -i inventory all.yml
```

Create custom snapshot when the database icinga2 is already created:
```bash
ansible-playbook -i inventory /{{ path to ansible-testing environment}}/snapshot-create-custom.yml --extra-vars "@group_vars/all.yml"
```
Get info about number of member nodes in cluster:
```bash
mysql -h 127.0.0.1 -u root -p123 -e 'SELECT VARIABLE_VALUE as "cluster size" FROM INFORMATION_SCHEMA.GLOBAL_STATUS WHERE VARIABLE_NAME="wsrep_cluster_size"'
```

The nodes should be restarted manually. The last node in the cluster has information "safe_to_bootstrap: 1" in file /dir-data/mariadb/grastate.dat

if it is other then the node1 all nodes should be run again with the command docker run and the first node with the "mysqld --wsrep-new-cluster" at the end of the command docker run

More detailed info are in README files in nested directories.
