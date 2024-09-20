#!/bin/sh

PI_BOOTSTRAP="${PI_BOOTSTRAP:-false}"
PI_UPDATE="${PI_UPDATE:-false}"
PI_PASSWORD=$(cat /run/secrets/pi_admin_pass)
PI_PORT="${PI_PORT:-8080}"
PI_LOGLEVEL="${PI_LOGLEVEL:-INFO}"
echo "$PI_ENCKEY" | base64 -d > /privacyidea/etc/enckey

# bootstrap system 
if [ ! -f /privacyidea/conf/enckey ] || [ -z $PI_ENCKEY ]
then
	source activate
	pi-manage setup create_enckey
	pi-manage setup create_tables || exit 1
	pi-manage db stamp head -d /privacyidea/lib/privacyidea/migrations/
	pi-manage admin add --password ${PI_PASSWORD:-admin} ${PI_ADMIN:-admin}
fi

if [ ! -f /privacyidea/etc/private.pem ]
then 
	pi-manage setup create_audit_keys
fi

# run DB schema update if requested
if [ "$1" == "UPDATE" ]
then
    echo "### RUNNING DB-SCHEMA UPDATE ###"
	source activate
	privacyidea-schema-upgrade /privacyidea/lib/privacyidea/migrations/
fi

# Run the app using gunicorn WSGI HTTP server
exec python -m gunicorn -w 4 -n pi_gunicorn -b 0.0.0.0:${PI_PORT} "privacyidea.app:create_app(config_name='production')"
