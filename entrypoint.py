import os
import base64
import pathlib

from privacyidea.app import create_app
from privacyidea.cli.pimanage.pi_setup import (create_pgp_keys)
from privacyidea.lib.security.default import DefaultSecurityModule
from privacyidea.lib.auth import create_db_admin
from privacyidea.models import db
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization

app = create_app(config_name='production',config_file='/privacyidea/etc/pi.cfg')

os.chdir('/privacyidea/venv/lib/python3.12/site-packages/privacyidea')

# Update database schema, if set
PI_UPDATE = os.environ.get('PI_UPDATE', False)

# Create enckey
if not os.path.exists('/privacyidea/etc/persistent/enckey') or os.path.getsize('/privacyidea/etc/persistent/enckey') == 0:
    if 'PI_ENCKEY' in os.environ and not os.path.exists('/privacyidea/etc/persistent/enckey'):
        with open('/privacyidea/etc/persistent/enckey', 'wb') as f:
            f.write(base64.b64decode(os.environ['PI_ENCKEY']))
        os.chmod('/privacyidea/etc/persistent/enckey', 0o400)
    else:
     enc_file = pathlib.Path('/privacyidea/etc/persistent/enckey')

    with open(enc_file, "wb") as f:
        f.write(DefaultSecurityModule.random(96))
        enc_file.chmod(0o400)

# Create audit keys if not exists
if not os.path.exists('/privacyidea/etc/persistent/private.pem'):
     
    priv_key = pathlib.Path(os.environ['PI_AUDIT_KEY_PRIVATE'])
    if not priv_key.is_file():
        new_key = rsa.generate_private_key(public_exponent=65537,
                                        key_size=2048,
                                        backend=default_backend())
        priv_pem = new_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption())
        with open(priv_key, "wb") as f:
            f.write(priv_pem)

        pub_key = pathlib.Path(os.environ['PI_AUDIT_KEY_PUBLIC'])
        public_key = new_key.public_key()
        pub_pem = public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo)
        with open(pub_key, "wb") as f:
            f.write(pub_pem)
    
                 
# Bootstrap database
if os.path.exists('/privacyidea/etc/persistent/enckey') and not os.path.exists('/privacyidea/etc/persistent/dbcreated'):
    with app.app_context():
        dbcreate = db.create_all()
    open('/privacyidea/etc/persistent/dbcreated', 'w').close()

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