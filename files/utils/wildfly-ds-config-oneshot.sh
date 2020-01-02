#!/bin/bash
# TODO: use curl or nc for testing if wildfly is up and running.
sleep 30

# Install the mysql jar file
/opt/wildfly/bin/jboss-cli.sh --connect --command="module add --name=com.mysql --resources=/opt/jdbc_drivers/mysql/main/mysql-connector-java-8.0.18.jar --dependencies=javax.api,javax.transaction.api"
# Create JDBC Driver DataSource
/opt/wildfly/bin/jboss-cli.sh --connect --command='/subsystem=datasources/jdbc-driver=mysql:add(driver-name="mysql",driver-module-name="com.mysql",driver-class-name=com.mysql.jdbc.Driver)'
# Create JNDI Datasource
/opt/wildfly/bin/jboss-cli.sh --connect --command="data-source add --jndi-name=java:/SignServerDS --name=SignServerDS --connection-url=jdbc:mysql://${SIGNSERVER_MYSQL_HOST}:3306/signserver --driver-name=mysql --user-name=${SIGNSERVER_MYSQL_USER} --password=${SIGNSERVER_MYSQL_PASSWORD}"

# Deploy SignServer 
cd /opt/signserver
bin/ant deploy