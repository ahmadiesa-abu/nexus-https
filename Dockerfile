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

RUN yum install -y systemd kmod libevent python3-pyyaml policycoreutils

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/libbasicobjects-0.1.1-39.el8.x86_64.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/libcollection-0.7.0-39.el8.x86_64.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/libpath_utils-0.2.1-39.el8.x86_64.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/libref_array-0.1.5-39.el8.x86_64.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/libini_config-1.3.1-39.el8.x86_64.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/libverto-libevent-0.3.0-5.el8.x86_64.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/libcom_err-1.45.6-2.el8.x86_64.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/rpcbind-1.2.5-8.el8.x86_64.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/gssproxy-0.8.0-19.el8.x86_64.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/e2fsprogs-libs-1.45.6-2.el8.x86_64.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/quota-nls-4.04-14.el8.noarch.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/quota-4.04-14.el8.x86_64.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/libnfsidmap-2.3.3-46.el8.x86_64.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/keyutils-1.5.10-9.el8.x86_64.rpm

RUN yum --disablerepo=* install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/nfs-utils-2.3.3-46.el8.x86_64.rpm

RUN yum install -y http://repo.okay.com.mx/centos/7/x86_64/release/amazon-efs-utils-1.7-1.el7.noarch.rpm

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
