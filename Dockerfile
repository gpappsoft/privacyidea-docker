### build stage
###
FROM cgr.dev/chainguard/wolfi-base AS builder

ARG PYVERSION=3.12
ARG PI=3.11
ARG PI_REQUIREMENTS=3.11
ARG GUNICORN==23.0.0
ARG PSYCOPG2==2.9.9
ENV LANG=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/privacyidea/venv/bin:$PATH"

WORKDIR /privacyidea
RUN apk add python-${PYVERSION} py${PYVERSION}-pip && \
        chown -R nonroot:nonroot /privacyidea/

USER nonroot
RUN python -m venv /privacyidea/venv
RUN pip install -r https://raw.githubusercontent.com/privacyidea/privacyidea/v${PI_REQUIREMENTS}/requirements.txt 
RUN pip install psycopg2-binary==${PSYCOPG2} privacyidea==${PI} gunicorn==${GUNICORN}

ADD https://raw.githubusercontent.com/privacyidea/privacyidea/v${PI_REQUIREMENTS}/deploy/privacyidea/NetKnights.pem /privacyidea/etc/persistent/

COPY  conf/pi.cfg /privacyidea/etc/
COPY  conf/logging.cfg /privacyidea/etc/
COPY  entrypoint.sh /privacyidea/venv/bin/entrypoint.sh

### final stage
###
FROM cgr.dev/chainguard/wolfi-base

ARG version=3.12
ENV PYTHONUNBUFFERED=1
ENV PATH="/privacyidea/venv/bin:/privacyidea/bin:$PATH"
ENV PRIVACYIDEA_CONFIGFILE="/privacyidea/etc/pi.cfg"
LABEL maintainer="Marco Moenig <marco@moenig.it>"
LABEL org.opencontainers.image.source=https://github.com/gpappsoft/privacyidea-docker.git
LABEL org.opencontainers.image.url=https://github.com/gpappsoft/privacyidea-docker.git

WORKDIR /privacyidea
VOLUME /privacyidea/etc/persistent

RUN apk add python-${version} 
#&& \ chown -R nonroot:nonroot /privacyidea/

COPY --from=builder /privacyidea/ /privacyidea        

EXPOSE ${PORT}

# Run privacyIDEA-Server
ENTRYPOINT [ "entrypoint.sh" ]
