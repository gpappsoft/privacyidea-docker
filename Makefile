PI_VERSION := 3.11
PI_VERSION_BUILD := 3.11
IMAGE_NAME := privacyidea-docker:${PI_VERSION}

BUILDER := docker build
CONTAINER_ENGINE := docker

PI_PEPPER := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
PI_SECRET := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
DB_PASSWORD := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
PI_ADMIN_PASS := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9$!%' | fold -w 16| head -n1)

SSL_SUBJECT="/C=DE/ST=SomeState/L=SomeCity/O=privacyIDEA/OU=reverseproxy/CN=localhost"

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
	@openssl req -x509 -newkey rsa:4096 -keyout templates/pi.key -out templates/pi.pem -sha256 -days 3650 -nodes -subj "${SSL_SUBJECT}" 2> /dev/null
	@echo Certificate generation done...

secrets:
	@echo Generate new secrets for environment file
	@echo -----------------------------------------
	@echo PI_SECRET=$(PI_SECRET)
	@echo PI_PEPPER=$(PI_PEPPER)
	@echo PI_ADMIN_PASS=$(PI_ADMIN_PASS)
	@echo DB_PASSWORD=$(DB_PASSWORD)
	@echo -----------------------------------------
	@echo Please replace within your environment file
	
stack:
	@PI_BOOTSTRAP="true" \
	${CONTAINER_ENGINE} compose --env-file=environment/application-${TAG}.env -p ${TAG} --profile=${PROFILE} up -d
	@echo 
	@echo Access to privacyIDEA Web-UI: https://localhost:8443
	
fullstack:
	@PI_BOOTSTRAP="true" \
	${CONTAINER_ENGINE} compose --env-file=environment/application-${TAG}.env -p ${TAG} --profile=fullstack up -d
	@echo 
	@echo Access to privacyIDEA Web-UI: https://localhost:8443

run:
	@${CONTAINER_ENGINE} run -d --name ${TAG}-privacyidea \
			-e PI_PASSWORD=admin \
			-e PI_ADMIN=admin \
			-e PI_ADMIN_PASS=admin \
			-e DB_PASSWORD=superSecret \
			-e PI_PEPPER=superSecret \
			-e PI_SECRET=superSecret \
			-e PI_PORT=8080 \
			-e PI_LOGLEVEL=INFO \
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
	@${CONTAINER_ENGINE} volume rm ${TAG}_mysql --force 

