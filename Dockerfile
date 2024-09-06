FROM python:3.12-slim
LABEL maintainer="Marco Moenig <marco@moenig.it>"

USER root
ARG PI_VERSION_BUILD=3.10.0.1
ARG PI_VERSION=3.10
ARG PI_PORT=8080
ARG UID=998

RUN mkdir /opt/privacyidea && \
    mkdir /etc/privacyidea && \
    mkdir /var/log/privacyidea

RUN useradd -u ${UID} -r -M -d /opt/privacyidea privacyidea && \
    groupmod -g ${UID} privacyidea && \
    chown -R privacyidea:privacyidea /opt/privacyidea /etc/privacyidea /var/log/privacyidea  

ENV HOME=/opt/privacyidea

USER privacyidea

WORKDIR /opt/privacyidea

RUN python -m venv /opt/privacyidea 
ENV PATH="/opt/privacyidea/:/opt/privacyidea/bin:$PATH"
RUN pip install --upgrade --force-reinstall pip 
RUN pip install -r https://raw.githubusercontent.com/privacyidea/privacyidea/v3.10/requirements.txt && \
    pip install psycopg2-binary && \
    pip install privacyidea==${PI_VERSION} && \
    pip install gunicorn

COPY --chown=privacyidea:privacyidea conf/pi.cfg /etc/privacyidea/
COPY --chown=privacyidea:privacyidea conf/logging.cfg /etc/privacyidea/
COPY --chown=privacyidea:privacyidea entrypoint.sh /opt/privacyidea/
COPY --chown=privacyidea:privacyidea templates/pi_healthcheck.py /opt/privacyidea/healthcheck.py

RUN chmod 640 /etc/privacyidea/pi.cfg  
RUN chmod 755 /opt/privacyidea/entrypoint.sh
RUN chmod 755 /opt/privacyidea/healthcheck.py

USER root

USER privacyidea

ADD --chown=privacyidea:privacyidea --chmod=755 https://raw.githubusercontent.com/privacyidea/privacyidea/v${PI_VERSION}/deploy/privacyidea/NetKnights.pem /etc/privacyidea/

EXPOSE ${PI_PORT}

# Run the server
CMD [ "./entrypoint.sh" ]
