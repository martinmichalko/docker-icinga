### start the icinga2 for testing purposes

first we should create the volume for local communication between icinga2 and icingaweb2

```bash
docker volume create --name=icinga2_cmd
```
then we can use this volume in command for container:

```bash
run -d --network host -v icinga2_cmd:/var/run/icinga2/cmd/ --name icinga2 icinga2
```
