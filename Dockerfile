FROM centos:7

LABEL is.opinkerfi.version="1.0.0-alpha" \
packager="Opin Kerfi hf." \
is.opinkerfi.release-date="2020-01-02" \
maintainer="Samúel Jón Gunnarsson <samuel@ok.is>"

ENV container docker
# Sign Server and Wildfly environment variables
ENV APPSRV_HOME=/opt/wildfly
ENV JAVA_HOME=/etc/alternatives/java_sdk_openjdk
ENV SIGNSERVER_NODEID=node1
ENV SIGNSERVER_MYSQL_USER=signserver
ENV SIGNSERVER_MYSQL_PASSWORD=signserver
ENV SIGNSERVER_MYSQL_HOST=db

# Systemd - preparation
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
# Systemd - preparation ends

# Install prerequsites part 1
RUN yum -y update && yum -y install java-1.8.0-openjdk mysql-connector-java ant maven unzip which wget && yum clean all -y
# Install prerequsites part 2
#COPY files/sources /tmp/
COPY files/utils /opt/utils

RUN cd /tmp; \
	wget https://download.jboss.org/wildfly/18.0.1.Final/wildfly-18.0.1.Final.zip; \
	unzip /tmp/wildfly-18.0.1.Final.zip -d /opt; \
	mv /opt/wildfly-18.0.1.Final /opt/wildfly; \
	groupadd -r wildfly; \
	useradd -r -g wildfly -d /opt/wildfly -s /sbin/nologin wildfly; \
	mkdir -p /etc/wildfly; \
	cp /opt/wildfly/docs/contrib/scripts/systemd/wildfly.conf /etc/wildfly/; \
	cp /opt/wildfly/docs/contrib/scripts/systemd/launch.sh /opt/wildfly/bin/; \
	chmod +x /opt/wildfly/bin/*.sh; \
	cp /opt/wildfly/docs/contrib/scripts/systemd/wildfly.service /etc/systemd/system/; \
	cd /tmp; \
	wget https://sourceforge.net/projects/signserver/files/signserver/5.0/signserver-ce-5.0.0.Final-bin.zip; \ 
	unzip /tmp/signserver-ce-5.0.0.Final-bin.zip -d /opt; \
	mv /opt/signserver-ce-5.0.0.Final /opt/signserver

# Copy mysql driver and deploy.properties
COPY files/config/signserver_deploy.properties /opt/signserver/conf/signserver_deploy.properties
COPY files/jdbc_drivers /opt/jdbc_drivers
COPY files/config/deploy-signserver.service /etc/systemd/system/

# Cleanup
RUN systemctl enable deploy-signserver; \
	systemctl enable wildfly; \
	rm /tmp/wildfly-18.0.1.Final.zip; \
	rm /tmp/signserver-ce-5.0.0.Final-bin.zip; \
	chown -R wildfly:wildfly /opt/signserver; \
	chown -R wildfly:wildfly /opt/wildfly; \
	chown -R wildfly:wildfly /etc/wildfly

VOLUME [ "/sys/fs/cgroup", "/opt/wildfly", "/opt/signserver" ]
WORKDIR /opt/wildfly
EXPOSE 8080/tcp
EXPOSE 8443/tcp
EXPOSE 9990/tcp

CMD ["/usr/sbin/init"]
HEALTHCHECK --interval=2m --timeout=3s CMD curl -f http://localhost:8080/ || exit 1
