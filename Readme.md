# Primekey Signing Server Community Edition
Container image for Primekey Signing Server Community Edition. Components involved are Centos 7, Wildfly 18.0.0 and Java OpenJDK 1.8.0.

[![Docker Stars](https://img.shields.io/docker/stars/opinkerfi/primekey-signing-server-ce.svg)]()
[![Docker Pulls](https://img.shields.io/docker/pulls/opinkerfi/primekey-signing-server-ce.svg)]()
[![GitHub tag](https://img.shields.io/github/tag/opinkerfi/primekey-signing-server-ce.svg)]()
[![GitHub release](https://img.shields.io/github/release/opinkerfi/primekey-signing-server-ce.svg)]()

## Usage

The container is running 
```
docker run \
  --name=my-signing-server \
  --privileged \
  -p 8080:8080 \
  -e SIGNSERVER_MYSQL_USER=signserver \
  -e SIGNSERVER_MYSQL_PASSWORD=signserver \
  -e SIGNSERVER_MYSQL_HOST=db \
  opinkerfi/primekey-signing-server-ce
```


## Parameters and environment variables

### Ports

* `-p 8080:8080` - Wildfly Server HTTP Port
* `-p 8443:8443` - Wildfly Server HTTPS (TLS) Port
* `-p 9990:9990` - Wildfly Server Managment Port

### Environment variables

The following environmental variables are used by the container and you must set at least _user_, _password_ and _host_ to point to the database that signing server will be using.

* `-e SIGNSERVER_MYSQL_USER=signingserver` - Signing Server MySQL User
* `-e SIGNSERVER_MYSQL_PASSWORD=signingserver` - Signing Server MySQL Password
* `-e SIGNSERVER_MYSQL_HOST=db` - Signing Server MySQL Hostname
* `-e SIGNSERVER_NODEID=node1` - Signing Server Node ID
* `-e SIGNSERVER_MYSQL_HOST` - Signing Server MySQL Hostname
* `-e APPSRV_HOME=/opt/wildfly` - Wildfly Server Home
* `-e JAVA_HOME=/etc/alternatives/java_sdk_openjdk` - Java Home
* `-e APPSRV_HOME=/opt/wildfly` - Wildfly Server Home

### Volumes

* `/opt/wildfly` - Wildfly home 
* `/opt/signserver` - Signserver home
* `/sys/fs/cgroup` - For systemd functionality

## Access 

To access Signing Server web
* http://localhost:8080/signserver
* https://localhost:8443/signserver

For shell access whilst the container is running do `docker exec -it my-signing-server /bin/bash`.

### Via docker-compose

```SHELL
docker-compose up
```
where the contents of docker-compose.yml is similar to the example provided

```YAML
version: '3.1'

services:
    db:
        image: mariadb
        environment:
            MYSQL_ROOT_PASSWORD: myroot-password
            MYSQL_USER: my-signing-server-user
            MYSQL_PASSWORD: my-signing-server-password
            MYSQL_DATABASE: signserver
        command: ['mysqld', '--character-set-server=utf8mb4', '--collation-server=utf8mb4_unicode_ci']

    signserver:
        image: opinkerfi/primekey-signing-server-ce:1.0.0-alpha
        privileged: true
        cap_add:
            - CAP_SYS_ADMIN
        ports:
            - 8080:8080/tcp
            - 8443:8443/tcp
            - 9990:9990/tcp
        depends_on: 
            - db
        environment:
            SIGNSERVER_MYSQL_USER: my-signing-server-user
            SIGNSERVER_MYSQL_PASSWORD: my-signing-server-password
            SIGNSERVER_MYSQL_HOST: db
        volumes:
            - /sys/fs/cgroup:/sys/fs/cgroup:ro

# The following php admin interface can be enabled for debugging. 
#    adminer:
#        image: adminer
#        ports:
#            - 8081:8080
```
