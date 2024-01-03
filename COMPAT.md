[![Docker](https://github.com/gpappsoft/privacyidea-docker/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/gpappsoft/privacyidea-docker/actions/workflows/docker-publish.yml)

# Compatibility for privacyidea-docker

This list is an overview of the linux-distributions and Docker versions the project was *roughly* tested. There is no guarantee that it will really work.

| Distribution | Docker/Podman | Version | Docker compose/buildx plugin | ```make build```| ```make stack```|Note|
|-----|-----|----|----|----|----|---|
|Ubuntu 22.04.3 LTS|Docker| 24.0.5, build 24.0.5-0ubuntu1~22.04.1|latest/latest|:white_check_mark:|:white_check_mark:|| | 
|Debian GNU/Linux 12 (bookworm)|Docker| 24.0.7 | latest/latest|:white_check_mark:|:white_check_mark:|| | 
|Debian GNU/Linux 11 (bullseye)|Docker| 20.10.5+dfsg1, build 55c4c88|latest/latest|:white_check_mark:|:white_check_mark:|| | 
|Fedora server 39|Docker|24.0.5|latest/latest|:white_check_mark:|:white_check_mark:|set selinux permissions| | 
|Debian GNU/Linux 12 (bookworm)|podman| 4.3.1| latest/latest|:white_check_mark:|:x:|| | 

Additions welcome!