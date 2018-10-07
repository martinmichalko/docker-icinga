## Common rules for docker container directories and their volumes

/etc/mysql/conf.d is local directory for custom configuration files.
/var/lib/mysql is local directory for database

These config and data files can be provided for the docker container as external volumes.

All three containers is used the same approach with directories on host
application=mariadb
/dir-config/{{ application }}/ is directory for external config files
/dir-data/{{ application }}/ is directory for external data files

directories in each container are:
/dir-config/
/dir-data/

USAGE RULES:
1. Config files - are part of docker files and they will be provided inside docker container as default files in directory structure of container  
- before application start check if dir-config provided and use them if yes
- if not provided use those in container structure
(so contaner will remember its own version of config files from inital build)
2. data files the can be in the dir-data in this case will be used already provisioned data
3. when the data files are not in the directory container during first run has to create data files - this case whole database before start
(so in each case data will be stored outside container in volume dir-data)

Icinga2 is exception because it is dynamically configured by cli command icingacli.
