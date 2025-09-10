### Build privacyidea container including gssapi (Kerberos) and hsm

### build stage
###
FROM cgr.dev/chainguard/wolfi-base AS builder

ARG PYVERSION=3.12
ARG PI_VERSION=3.12
ARG PI_REQUIREMENTS=3.12
ARG GUNICORN==23.0.0
ARG PSYCOPG2==2.9.10
ARG PYKCS11==1.5.14

ENV LANG=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/privacyidea/venv/bin:$PATH"

WORKDIR /privacyidea
RUN apk add python-${PYVERSION} py${PYVERSION}-pip python3-dev gnupg && \
#RUN apk add python-${PYVERSION} py${PYVERSION}-pip python3-dev build-base krb5-conf krb5-dev swig && \
        chown -R nonroot:nonroot /privacyidea/

USER nonroot
RUN python -m venv /privacyidea/venv
RUN pip install -r https://raw.githubusercontent.com/privacyidea/privacyidea/refs/tags/v${PI_REQUIREMENTS}/requirements.txt
RUN pip install psycopg2-binary==${PSYCOPG2} gunicorn==${GUNICORN} gnupg
RUN pip install privacyIDEA==${PI_VERSION}
#RUN pip install -r https://raw.githubusercontent.com/privacyidea/privacyidea/v${PI_REQUIREMENTS}/requirements-kerberos.txt 
# Workaroud for https://github.com/privacyidea/privacyidea/issues/4127
#RUN pip install -r https://raw.githubusercontent.com/privacyidea/privacyidea/v${PI_REQUIREMENTS}/requirements-hsm.txt 
#RUN pip install pykcs11==${PYKCS11}

ADD https://raw.githubusercontent.com/privacyidea/privacyidea/refs/tags/v${PI_REQUIREMENTS}/deploy/privacyidea/NetKnights.pem /privacyidea/etc/persistent/

COPY  conf/pi.cfg /privacyidea/etc/
COPY  conf/logging.cfg /privacyidea/etc/
COPY  entrypoint.py /privacyidea/entrypoint.py
COPY  templates/healthcheck.py /privacyidea/healthcheck.py

### final stage
###
FROM cgr.dev/chainguard/wolfi-base

ARG PYVERSION=3.12
ENV PYTHONUNBUFFERED=1
ENV PATH="/privacyidea/venv/bin:/privacyidea/bin:$PATH"
ENV PRIVACYIDEA_CONFIGFILE="/privacyidea/etc/pi.cfg"
LABEL maintainer="Marco Moenig <marco@moenig.it>"
LABEL org.opencontainers.image.source="https://github.com/gpappsoft/privacyidea-docker.git"
LABEL org.opencontainers.image.url="https://github.com/gpappsoft/privacyidea-docker.git"
LABEL org.opencontainers.image.description="Simply deploy and run a privacyIDEA instance in a container environment."

WORKDIR /privacyidea
VOLUME /privacyidea/etc/persistent

RUN apk add python-${PYVERSION} 

COPY --from=builder /privacyidea/ /privacyidea     

EXPOSE ${PI_PORT}

# Run privacyIDEA-Server
ENTRYPOINT [ "python", "/privacyidea/entrypoint.py" ]
