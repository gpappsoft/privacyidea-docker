#!/bin/bash

# set default if missing
PI_BOOTSTRAP="${PI_BOOTSTRAP:-false}"
PI_UPDATE="${PI_UPDATE:-false}"
PI_PASSWORD=$(cat /run/secrets/pi_admin_pass)
PI_PORT="${PI_PORT:-8080}"
PI_LOGLEVEL="${PI_LOGLEVEL:-INFO}"

# temporary solution to set loglevel in logging.cnf 
sed  -i -e "s/^\(\s\{4\}level:\s\).*\(##PI_LOGLEVEL##\)$/\1$PI_LOGLEVEL \2/g" /etc/privacyidea/logging.cfg 

# check if already bootstrapped
[ -f /etc/privacyidea/BOOTSTRAP ] && PI_BOOTSTRAP=false

# bootstrap system
if [ "${PI_BOOTSTRAP}" == "true" ] 
then
	source bin/activate
	pi-manage create_enckey
	pi-manage create_audit_keys
	pi-manage createdb || exit 1
	pi-manage db stamp head -d /opt/privacyidea/lib/privacyidea/migrations/
	pi-manage admin add ${PI_ADMIN:-admin} -p ${PI_PASSWORD:-admin}
	echo "Remove file to bootstrap instance again." >> /etc/privacyidea/BOOTSTRAP
fi

# run DB schema update if env PI_UPDATE is true
if [ "${PI_UPDATE}" == "true" ]
then
    echo "### RUNNING DB-SCHEMA UPDATE ###"
	source bin/activate
	privacyidea-schema-upgrade /opt/privacyidea/lib/privacyidea/migrations/
fi

# Run the server using gunicorn WSGI HTTP server
exec /opt/privacyidea/bin/gunicorn "privacyidea.app:create_app(config_name='production')" -w 4 -b 0.0.0.0:${PI_PORT}
