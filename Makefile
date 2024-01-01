PI_VERSION := 3.9.1
IMAGE_NAME := privacyidea-docker:${PI_VERSION}

BUILDER := docker build
CONTAINER_ENGINE := docker

PEPPER := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
SECRET := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
DB_PASSWORD := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
PI_ADMIN_PASS := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9$!%' | fold -w 16| head -n1)
REGISTRY := localhost:5000
PORT := 8080
TAG := pi

build:
	${BUILDER} . --no-cache -t ${IMAGE_NAME} --build-arg PI_VERSION=${PI_VERSION}

push:
	${CONTAINER_ENGINE} tag ${IMAGE_NAME} ${REGISTRY}/${IMAGE_NAME}
	${CONTAINER_ENGINE} push ${REGISTRY}/${IMAGE_NAME}


cert:
	@openssl req -x509 -newkey rsa:4096 -keyout ssl/pi.key -out ssl/pi.pem -sha256 -days 3650 -nodes -subj "/C=DE/ST=SomeState/L=SomeCity/O=privacyIDEA/OU=reverseproxy/CN=localhost"

secret:
	@echo -n "Warnign! Overwrite ALL SECRETS  in ./secrets directory: Are you sure? [y/N] " && read ans && if [ $${ans:-'N'} = 'y' ]; then make make_secrets; fi

make_secrets:
	@echo Generate new secrets...
	@echo -n "SECRET_KEY: "
	@echo $(SECRET) | tee secrets/pi_secret
	@echo -n "PI_PEPPER: "
	@echo $(PEPPER) | tee secrets/pi_pepper
	@echo -n "PI database password: "
	@echo $(DB_PASSWORD) | tee secrets/db_password
	@echo -n "PI admin password: "
	@echo $(PI_ADMIN_PASS) | tee secrets/pi_admin_pass
	
stack:
	@PI_BOOTSTRAP="true" \
	${CONTAINER_ENGINE} compose --env-file=examples/application-prod.env -p ${TAG} up -d

run:
	@${CONTAINER_ENGINE} run -d --name ${TAG}-privacyidea \
			-e PI_PASSWORD=admin \
			-e PI_ADMIN=admin \
			-e PI_PEPPER=superSecret \
			-e PI_SECRET=superSecret \
			-e PI_PORT=8080 \
			-e PI_BOOTSTRAP=true \
			-e PI_REGISTRY_CLASS=null \
			-e PI_LOGLEVEL=DEBUG \
			-v ${TAG}-pilog:/var/log/privacyidea:rw,Z \
			-v ${TAG}-piconfig:/etc/privacyidea:rw,Z \
			-p ${PORT}:${PORT} \
			${IMAGE_NAME}
	@echo Access to privacyIDEA Web-UI: https://localhost:${PORT}
	@echo Username/Password: admin / admin

clean:
	@${CONTAINER_ENGINE} rm --force ${TAG}-privacyidea

distclean:
	@echo -n "Warning! This will remove all related volumes: Are you sure? [y/N] " && read ans && if [ $${ans:-'N'} = 'y' ]; then make make_distclean; fi

make_distclean:
	@echo Remove container and volumes
	@${CONTAINER_ENGINE} rm --force ${TAG}-privacyidea
	@${CONTAINER_ENGINE} volume rm ${TAG}-pilog ${TAG}-piconfig --force 

