import os
import base64
from time import sleep
from privacyidea.app import create_app
from privacyidea.cli.pimanage.pi_setup import (create_enckey, create_audit_keys,create_pgp_keys)
from privacyidea.lib.auth import create_db_admin
from privacyidea.models import db


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
        create_audit_keys()
        create_pgp_keys()

# Bootstrap database
if os.path.exists('/privacyidea/etc/persistent/enckey') and not os.path.exists('/privacyidea/etc/persistent/dbcreated'):
    print("### Creating database tables ###")
    with app.app_context():
        dbcreate = db.create_all()
    open('/privacyidea/etc/persistent/dbcreated', 'w').close()

print("### Create initial admin user ###")
with app.app_context():
    create_db_admin(os.environ.get('PI_ADMIN', 'admin'), 'email',os.environ.get('PI_ADMIN_PASS', 'admin'))

# Run the app using gunicorn WSGI HTTP server
cmd = [ "python",
    "-m", "gunicorn",
    "-w", "1",
    "-b", os.environ['PI_ADDRESS']+":"+os.environ['PI_PORT'],
    "privacyidea.app:create_app(config_name='production',config_file='/privacyidea/etc/pi.cfg')"
]

os.execvp('python', cmd)