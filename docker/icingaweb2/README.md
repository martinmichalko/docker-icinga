### start the icingaweb2 for testing purposes

first we should create the volume for local communication between icinga2 and icingaweb2

```bash
docker volume create --name=icinga2_cmd
```
then we can use this volume in command for container icinga2:

```bash
docker run -d --network host -v icinga2_cmd:/var/run/icinga2/cmd/ --name icinga2 icinga2
```

and finally we can run also icingaweb2
```bash

docker run -d --network host -v icinga2_cmd:/var/run/icinga2/cmd/ --name icingaweb2 icingaweb2
```
### Configuring after deployment

Visit the following link to begin setting up the Icinga Web 2; you would need to go through the setup wizard and complete the installation of Icinga Web 2.

http://your-ip-addr-ess/icingaweb2/setup


For security reason, you would require to generate the token and paste it on the first step of the wizard.

The token you get form the file stored in main config directory:
cat /dir-config/icingaweb2/setup.token
