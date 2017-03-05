### start the icinga2 for testing purposes

this docker container installs the single icinga2 master

Create the volume for local communication between icinga2 and icingaweb2 services

```bash
docker volume create --name=icinga2_cmd
```
then we can use this volume in command for container:

```bash
docker run --rm --network host -v icinga2_cmd:/var/run/icinga2/cmd/ --name icinga2 icinga2
```
