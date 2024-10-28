import os
import base64
from time import sleep
from privacyidea.app import create_app
from privacyidea.cli.pimanage.pi_setup import (create_enckey, create_tables,create_audit_keys,create_pgp_keys)
from privacyidea.lib.auth import create_db_admin

app = create_app(config_name='production',config_file='/privacyidea/etc/pi.cfg')

os.chdir('/privacyidea/venv/lib/python3.12/site-packages/privacyidea')

# Update database schema, if set
PI_UPDATE = os.environ.get('PI_UPDATE', False)

# Create enckey
if not os.path.exists('/privacyidea/etc/persistent/enckey') or os.path.getsize('/privacyidea/etc/persistent/enckey') == 0:
    print("### Create enckey ###")
    if 'PI_ENCKEY' in os.environ and not os.path.exists('/privacyidea/etc/persistent/enckey'):
        print("### Use PI_ENCKEY ###")
        with open('/privacyidea/etc/persistent/enckey', 'wb') as f:
            f.write(base64.b64decode(os.environ['PI_ENCKEY']))
        os.chmod('/privacyidea/etc/persistent/enckey', 0o400)
    else:
        print("### Use create_enckey() ###")
        with app.app_context():
            create_enckey()

# Create audit keys if not exists
if not os.path.exists('/privacyidea/etc/persistent/private.pem'):
    print("### Create audit and pgp keys ###")
    with app.app_context():
    #audit = getAudit()
        create_audit_keys()
        create_pgp_keys()

# Bootstrap database
if os.path.exists('/privacyidea/etc/persistent/enckey') and not os.path.exists('/privacyidea/etc/persistent/dbcreated'):
    print("### Creating database tables ###")

    with app.app_context():
        create_tables()

    open('/privacyidea/etc/persistent/dbcreated', 'w').close()
    print("### Create initial admin user ###")
    with app.app_context():
        create_db_admin(app, os.environ.get('PI_ADMIN', 'admin'), os.environ.get('PI_ADMIN_PASS', 'admin'))


# # # Import resolver.json if exists
# if os.path.exists('/privacyidea/etc/persistent/resolver.json'):
#     with app.app_context():
#         with open('/privacyidea/etc/persistent/resolver.json', 'r') as f:
#           resolver_config = f.read()
#           save_resolver(resolver_config)
#     os.rename('/privacyidea/etc/persistent/resolver.json', '/privacyidea/etc/persistent/resolver.json_deployed')

# # Run DB schema update if requested
# if PI_UPDATE == True:
#     print("### RUNNING DB-SCHEMA UPDATE ###")
#     with app.app_context():
#         upgrade()

# Run the app using gunicorn WSGI HTTP server
cmd = [ 'python',
    '-m', 'gunicorn',
    '-w', '1',
    '-b', "$PI_ADDRESS:$PI_PORT",
    'privacyidea.app:create_app(config_name="production")'
]

os.execvp('python', cmd)