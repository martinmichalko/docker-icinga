#!/bin/bash
set -e
set -x

#In  general,  apache2  should  not  be  invoked directly, but rather should be invoked via
#/etc/init.d/apache2 or apache2ctl. The default Debian configuration  requires  environment
#variables  that	are  defined  in /etc/apache2/envvars and are not available if apache2 is
#started directly.  However, apache2ctl can be used to pass arbitrary arguments to apache2.

#environment variables in
source /etc/apache2/envvars

#ICINGA@ part

initfile="/app/first-run-done";
# check if this is first container run
if [ ! -f "${initfile}" ]; then
    echo "first start running";
    addgroup --system icingaweb2
    usermod -a -G icingaweb2 www-data

    echo "For security reason, you would require to generate the token and paste it on the first step of the wizard."
    icingacli setup token create

    echo "timezone set to Europe/Bratislava"
    sed -i -- 's|;date.timezone =|date.timezone = "Europe/Bratislava"|' /etc/php5/apache2/php.ini

    #if there is external config file provided in dir-config
    if [ -f /dir-config/config.ini ]; then
        echo "external config provided - link will be created";
        rm -r /etc/icingaweb2;
        ln -s /dir-config /etc/icingaweb2;
    fi;

    touch ${initfile};
    echo "first start finished";
fi;

#and apache2ctl with config file and foreground
exec "$@"
