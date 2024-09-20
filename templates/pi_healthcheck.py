#!/privacyidea/bin/python
import requests
import os

BASE_URL= "http://" + os.getenv('HOSTNAME') + ":" + os.getenv('PI_PORT') 

response = requests.get(BASE_URL)
assert response.status_code == 200, "Unexpected status code: " + str(response.status_code)
