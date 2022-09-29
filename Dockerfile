FROM sonatype/nexus3

LABEL maintainer="ahmadiesa@gmail.com"

ENV NEXUS_SSL=${NEXUS_HOME}/etc/ssl
ENV PUBLIC_CERT=${NEXUS_SSL}/cacert.pem \
    SERVERNAME=localhost \
    SERVERIP=127.0.0.1 \
    PRIVATE_KEY=${NEXUS_SSL}/cakey.pem \
    PRIVATE_KEY_PASSWORD=password

ARG GOSU_VERSION=1.13

USER root

RUN microdnf install yum

RUN yum -y update && yum install -y openssl libxml2 libxslt hostname iproute && yum clean all

RUN set -eux;\
    curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64"; \
    curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64.asc"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
    rm -rf /root/.gnupg/ /usr/local/bin/gosu.asc; \
    command -v gpgconf && gpgconf --kill all || :; \
    chmod +x /usr/local/bin/gosu; \
    gosu --version; \
    gosu nobody true

RUN sed \
    -e '/^nexus-args/ s:$:,${jetty.etc}/jetty-https.xml:' \
    -e '/^application-port/a \
application-port-ssl=8443\
' \
    -i ${NEXUS_HOME}/etc/nexus-default.properties

COPY entrypoint.sh ${NEXUS_HOME}/entrypoint.sh
COPY generateCertificate.sh ${NEXUS_HOME}/generateCertificate.sh
RUN chown nexus:nexus ${NEXUS_HOME}/generateCertificate.sh

RUN chown nexus:nexus ${NEXUS_HOME}/entrypoint.sh && chmod a+x ${NEXUS_HOME}/entrypoint.sh

VOLUME [ "${NEXUS_SSL}" ]

EXPOSE 8443
WORKDIR ${NEXUS_HOME}

ENTRYPOINT [ "./entrypoint.sh" ]

CMD [ "bin/nexus", "run" ]