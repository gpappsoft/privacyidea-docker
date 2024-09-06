PI_VERSION := 3.10.0.1
PI_VERSION_BUILD := 3.10.0.1
IMAGE_NAME := privacyidea-docker:${PI_VERSION}

BUILDER := docker build
CONTAINER_ENGINE := docker

PEPPER := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
SECRET := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
DB_PASSWORD := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
PI_ADMIN_PASS := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9$!%' | fold -w 16| head -n1)
REGISTRY := localhost:5000
PORT := 8080
TAG := prod
PROFILE := stack

build:
	${BUILDER} --no-cache -t ${IMAGE_NAME} --build-arg PI_VERSION_BUILD=${PI_VERSION_BUILD} --build-arg PI_VERSION=${PI_VERSION} .

push:
	${CONTAINER_ENGINE} tag ${IMAGE_NAME} ${REGISTRY}/${IMAGE_NAME}
	${CONTAINER_ENGINE} push ${REGISTRY}/${IMAGE_NAME}


cert:
	@openssl req -x509 -newkey rsa:4096 -keyout ssl/pi.key -out ssl/pi.pem -sha256 -days 3650 -nodes -subj "/C=DE/ST=SomeState/L=SomeCity/O=privacyIDEA/OU=reverseproxy/CN=localhost" 2> /dev/null
	@echo Certificate generation done...

secret:
	@echo -n "Warnign! Overwrite ALL SECRETS  in ./secrets directory: Are you sure? [y/N] " && read ans && if [ $${ans:-'N'} = 'y' ]; then make make_secrets; fi

make_secrets:
	@echo Generate new secrets...
	@echo ---------------------------
	@echo -n "SECRET_KEY: \t\t"
	@echo $(SECRET) | tee secrets/pi_secret
	@echo -n "PI_PEPPER: \t\t"
	@echo $(PEPPER) | tee secrets/pi_pepper
	@echo -n "PI database password: \t"
	@echo $(DB_PASSWORD) | tee secrets/db_password
	@echo -n "PI admin password: \t"
	@echo $(PI_ADMIN_PASS) | tee secrets/pi_admin_pass
	@echo ---------------------------
	
stack:
	@PI_BOOTSTRAP="true" \
	${CONTAINER_ENGINE} compose --env-file=environment/application-${TAG}.env -p ${TAG} --profile=${PROFILE} up -d
	@echo 
	@echo Access to privacyIDEA Web-UI: https://localhost:8443
	@echo -n "Username/Password: admin / "
	@cat secrets/pi_admin_pass

fullstack:
	@PI_BOOTSTRAP="true" \
	${CONTAINER_ENGINE} compose --env-file=environment/application-${TAG}.env -p ${TAG} --profile=fullstack up -d
	@${CONTAINER_ENGINE} exec -d ${TAG}-privacyidea-1 /bin/bash -c -i "pi-manage config importer -i /etc/privacyidea/resolver.json &>/dev/null" &>/dev/null
	@echo 
	@echo Access to privacyIDEA Web-UI: https://localhost:8443
	@echo -n "Username/Password: admin / "
	@cat secrets/pi_admin_pass


	
run:
	@${CONTAINER_ENGINE} run -d --name ${TAG}-privacyidea \
			-e PI_PASSWORD=admin \
			-e PI_ADMIN=admin \
			-e DB_PASSWORD=none \
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
	@echo Access to privacyIDEA Web-UI: http://localhost:${PORT}
	@echo Username/Password: admin / admin

clean:
	@${CONTAINER_ENGINE} rm --force ${TAG}-privacyidea

distclean:
	@echo -n "Warning! This will remove all related volumes: Are you sure? [y/N] " && read ans && if [ $${ans:-'N'} = 'y' ]; then make make_distclean; fi

make_distclean:
	@echo Remove container and volumes
	@${CONTAINER_ENGINE} rm --force ${TAG}-privacyidea
	@${CONTAINER_ENGINE} volume rm ${TAG}-pilog ${TAG}-piconfig --force 

