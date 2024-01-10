#!/bin/bash

# create secrets
for I in $(find secrets/ -type f -printf "%f\n" )
do 
    podman secret create ${I^^} ./secrets/$I 
done

if [ "$1" == "fullstack" ]
then
    FULLSTACK="-p 1812:1812/tcp -p 1812:1812/udp -p 1813:1813/udp -p 1389:389"
 
    podman pod create -p 8443:443 $FULLSTACK pi
 
    #start freeradius
    podman run --pod pi -dt --name=freeradius \
    -e RADIUS_PI_HOST=reverse_proxy \
    -v ./templates/clients.conf:/etc/raddb/clients.conf:ro \
    --restart=always gpappsoft/privacyidea-freeradius:3.4.2
 
    #start openldap
    podman run --pod pi -dt --name=openldap \
        -e KEEP_EXISTING_CONFIG=false \
        -e LDAP_REMOVE_CONFIG_AFTER_SETUP=true \
        -e LDAP_SSL_HELPER_PREFIX=ldap \
        -e LDAP_LOG_LEVEL=0 \
        -e LDAP_ORGANISATION="Example Inc." \
        -e LDAP_DOMAIN="example.org" \
        -e LDAP_BASE_DN="dc=example,dc=org" \
        -e LDAP_ADMIN_PASSWORD=openldap \
        -e LDAP_CONFIG_PASSWORD=config \
        -e LDAP_READONLY_USER=false \
        -e LDAP_SEED_INTERNAL_LDIF_PATH=/ldif \
        -e LDAP_RFC2307BIS_SCHEMA=true \
        -v ./templates/sample.ldif:/ldif/sample.ldif:ro \
        --restart=always osixia/openldap:latest
       
 else 
    podman pod create -p 8443:443 pi
fi


# start mariadb 
podman run --pod pi -dt --name=db \
    --secret DB_PASSWORD,target=/run/secrets/db_password \
    -e MARIADB_RANDOM_ROOT_PASSWORD=1 -e MARIADB_DATABASE=pi \
    -e MARIADB_USER=pi -e MARIADB_PASSWORD_FILE=/run/secrets/db_password \
    -e MARIADB_MYSQL_LOCALHOST_USER=true \
    -v mysql:/var/lib/mysq \
    --restart=always mariadb:latest  

# start privacyidea
podman run --pod pi -dt --name=privacyidea \
    --env-file=environment/application-prod.env  \
    --secret DB_PASSWORD,target=/run/secrets/db_password \
    --secret PI_PEPPER,target=/run/secrets/pi_pepper \
    --secret PI_SECRET,target=/run/secrets/pi_pepper \
    --secret PI_ADMIN_PASS,target=/run/secrets/pi_admin_pass \
    -v pilog:/var/log/privacyidea:rw,Z \
    -v piconfig:/etc/privacyidea:rw,Z \
    -v ./templates/resolver.json:/etc/privacyidea/resolver.json:rw,Z \
    -e PI_BOOTSTRAP="true" \
    -e DB_PASSWORD=/run/secrets/db_password \
    -e PI_SECRET=/run/secrets/PI_SECRET \
    -e PI_PEPPER=/var/run/PI_PEPPER \
    -e DB_HOST="localhost" \
    -e DB_EXTRA_PARAMS="?charset=utf8" \
    --restart=always gpappsoft/privacyidea-docker:3.9.2

# start reverse_proxy
podman run --pod pi -dt --name=reverse_proxy \
    --env-file=environment/application-prod.env \
    -e APP_PORT=8080 \
    -e PROXY_SERVERNAME=localhost \
    -v ./templates/nginx.conf:/etc/nginx/nginx.conf:ro \
    -v ./templates/nginx_default.conf.template:/etc/nginx/templates/default.conf.template:ro \
    -v ./ssl/pi.pem:/etc/nginx/ssl/pi.pem:ro \
    -v  ./ssl/pi.key:/etc/nginx/ssl/pi.key:ro \
    --restart=always nginx:latest


if [ "$1" == "fullstack" ]
then 
    echo -n "Waiting for privacyidea to depoly sample data "
    while ! $(podman exec -ti privacyidea bash -c "HOSTNAME=localhost PI_PORT=8080 /opt/privacyidea/healthcheck.py &>/dev/null" &>/dev/null)
    do 
        sleep 1
        echo -n . 
    done
    # deploy resolver
    podman exec -d privacyidea /bin/bash -c -i "pi-manage config importer -i /etc/privacyidea/resolver.json &>/dev/null" &>/dev/null
    echo done
fi



echo https://localhost:8443
echo -n username: admin / password:
cat secrets/pi_admin_pass
