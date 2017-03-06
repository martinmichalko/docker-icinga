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

### Commands to prepare mariadb cluster and single icinga2 and icingaweb2
You need also playbooks from my previous ansible-testing environment project https://github.com/martinmichalko/ansible-testing_environment
and these 4 commands unite the whole work to deploy 3 virtual machines with docker containers
for mariadb and icinga2

```bash
#build the environment
ansible-playbook -i inventory /{{ path to ansible-testing environment}}/create-update-config.yml --extra-vars "@group_vars/all.yml" -e 'ansible_python_interpreter=/usr/bin/python'
#prepare for python3
ansible-playbook -i inventory -e 'ansible_python_interpreter=/usr/bin/python' packages-req.yml
#prepare for db and apache
ansible-playbook -i inventory all.yml
#create custom snapshot when the database icinga2 is already created
ansible-playbook -i inventory /{{ path to ansible-testing environment}}/snapshot-create-custom.yml --extra-vars "@group_vars/all.yml" -e 'ansible_python_interpreter=/usr/bin/python'
```
Get info about number of member nodes in cluster:

```bash
mysql -h 127.0.0.1 -u root -p123 -e 'SELECT VARIABLE_VALUE as "cluster size" FROM INFORMATION_SCHEMA.GLOBAL_STATUS WHERE VARIABLE_NAME="wsrep_cluster_size"'
```

The nodes should be restarted manually. The last node in the cluster has information "safe_to_bootstrap: 1" in file /dir-data/mariadb/grastate.dat

if it is other then the node1 all nodes should be run again with the command docker run and the first node with the "mysqld --wsrep-new-cluster" at the end of the command docker run

More detailed info are in README files in nested directories.
