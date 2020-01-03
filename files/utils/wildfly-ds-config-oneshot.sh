#!/bin/bash
# TODO: use curl or nc for testing if wildfly is up and running.
sleep 30
echo "######################################"
echo "# Configuring Wildfly for Sign Server"
echo "######################################"
# Install the mysql jar file
echo "Deploying JAR file for MySQL"
/opt/wildfly/bin/jboss-cli.sh --connect --command="module add --name=com.mysql --resources=/opt/jdbc_drivers/mysql/main/mysql-connector-java-8.0.18.jar --dependencies=javax.api,javax.transaction.api"
# Create JDBC Driver DataSource
echo "Defining JDBC driver"
/opt/wildfly/bin/jboss-cli.sh --connect --command='/subsystem=datasources/jdbc-driver=mysql:add(driver-name="mysql",driver-module-name="com.mysql",driver-class-name=com.mysql.jdbc.Driver)'
# Create JNDI Datasource
echo "Adding DataSource"
#/opt/wildfly/bin/jboss-cli.sh --connect --command="data-source add --jndi-name=java:/SignServerDS --name=SignServerDS --connection-url=jdbc:mysql://${SIGNSERVER_MYSQL_HOST}:3306/signserver --driver-name=mysql --user-name=${SIGNSERVER_MYSQL_USER} --password=${SIGNSERVER_MYSQL_PASSWORD}"
/opt/wildfly/bin/jboss-cli.sh --connect --command="data-source add --name=signserverds --driver-name=mysql --connection-url=jdbc:mysql://${SIGNSERVER_MYSQL_HOST}:3306/signserver --jndi-name=java:/SignServerDS --use-ccm=true --driver-class=com.mysql.jdbc.Driver --user-name=${SIGNSERVER_MYSQL_USER} --password=${SIGNSERVER_MYSQL_PASSWORD} --validate-on-match=true --background-validation=false --prepared-statements-cache-size=50 --share-prepared-statements=true --min-pool-size=5 --max-pool-size=150 --pool-prefill=true --transaction-isolation=TRANSACTION_READ_COMMITTED --check-valid-connection-sql=\"select 1;\" --enabled=true"
/opt/wildfly/bin/jboss-cli.sh --connect --command=":reload"

# https://doc.primekey.com/signserver500/signserver-installation/application-server-setup/wildfly-10+-and-jboss-eap-7-1+

mkdir -p ${APPSRV_HOME}/standalone/configuration/keystore
cp /opt/signserver/res/test/dss10/dss10_demo-tls.jks ${APPSRV_HOME}/standalone/configuration/keystore/keystore.jks
cp /opt/signserver/res/test/dss10/dss10_truststore.jks ${APPSRV_HOME}/standalone/configuration/keystore/truststore.jks

# Remove any existing TLS and HTTP configuration and allow configuring port 8443
/opt/wildfly/bin/jboss-cli.sh --connect --command="/subsystem=undertow/server=default-server/http-listener=default:remove"
/opt/wildfly/bin/jboss-cli.sh --connect --command="/subsystem=undertow/server=default-server/https-listener=https:remove"
/opt/wildfly/bin/jboss-cli.sh --connect --command="/socket-binding-group=standard-sockets/socket-binding=http:remove"
/opt/wildfly/bin/jboss-cli.sh --connect --command="/socket-binding-group=standard-sockets/socket-binding=https:remove"
sleep 5
/opt/wildfly/bin/jboss-cli.sh --connect --command=":reload"
sleep 5
# Configure interfaces using the appropriate bind address.
/opt/wildfly/bin/jboss-cli.sh --connect --command='/interface=http:add(inet-address="0.0.0.0")'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/interface=httpspub:add(inet-address="0.0.0.0")'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/interface=httpspriv:add(inet-address="0.0.0.0")'

# Configure the HTTPS httpspriv listener and set up the private port requiring the client certificate.
/opt/wildfly/bin/jboss-cli.sh --connect --command='/core-service=management/security-realm=SSLRealm:add()'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/core-service=management/security-realm=SSLRealm/server-identity=ssl:add(keystore-path="keystore/keystore.jks", keystore-relative-to="jboss.server.config.dir", keystore-password="serverpwd", alias="localhost")'
sleep 5
/opt/wildfly/bin/jboss-cli.sh --connect --command=':reload'
sleep 5
# Configure the default HTTP listener.
/opt/wildfly/bin/jboss-cli.sh --connect --command='/core-service=management/security-realm=SSLRealm/authentication=truststore:add(keystore-path="keystore/truststore.jks", keystore-relative-to="jboss.server.config.dir", keystore-password="changeit")'
sleep 5
/opt/wildfly/bin/jboss-cli.sh --connect --command=':reload'
sleep 5
# Configure the HTTPS httpspub listener and set up the public SSL port not requiring the client certificate.
/opt/wildfly/bin/jboss-cli.sh --connect --command='/socket-binding-group=standard-sockets/socket-binding=httpspriv:add(port="8443",interface="httpspriv")'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/subsystem=undertow/server=default-server/https-listener=httpspriv:add(socket-binding="httpspriv", security-realm="SSLRealm", verify-client=REQUIRED, max-post-size="10485760", enable-http2="false")'
# Configure the default HTTP listener
/opt/wildfly/bin/jboss-cli.sh --connect --command='/socket-binding-group=standard-sockets/socket-binding=http:add(port="8080",interface="http")'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/subsystem=undertow/server=default-server/http-listener=default:add(socket-binding=http, max-post-size="10485760", enable-http2="false")'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/subsystem=undertow/server=default-server/http-listener=default:write-attribute(name=redirect-socket, value="httpspriv")'
sleep 5
/opt/wildfly/bin/jboss-cli.sh --connect --command=':reload'
sleep 5
# Configure the HTTPS httpspub listener and set up the public SSL port not requiring the client certificate.
/opt/wildfly/bin/jboss-cli.sh --connect --command='/socket-binding-group=standard-sockets/socket-binding=httpspub:add(port="8442",interface="httpspub")'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/subsystem=undertow/server=default-server/https-listener=httpspub:add(socket-binding="httpspub", security-realm="SSLRealm", max-post-size="10485760", enable-http2="false")'
#Configure the remoting (HTTP) listener and secure the CLI by removing the http-remoting-connector from using the HTTP port and instead use a separate port 4447.
/opt/wildfly/bin/jboss-cli.sh --connect --command='/subsystem=remoting/http-connector=http-remoting-connector:remove'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/subsystem=remoting/http-connector=http-remoting-connector:add(connector-ref="remoting",security-realm="ApplicationRealm")'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/socket-binding-group=standard-sockets/socket-binding=remoting:add(port="4447")'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/subsystem=undertow/server=default-server/http-listener=remoting:add(socket-binding=remoting, max-post-size="10485760", enable-http2="false")'
# In order for the web services to work correctly when requiring client certificate, you need to configure the Web Services Description Language (WSDL) web-host rewriting to use the request host.
/opt/wildfly/bin/jboss-cli.sh --connect --command='/subsystem=webservices:write-attribute(name=wsdl-host, value=jbossws.undefined.host)'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/subsystem=webservices:write-attribute(name=modify-wsdl-address, value=true)'
sleep 5
/opt/wildfly/bin/jboss-cli.sh --connect --command=':reload'
sleep 5
# To configure the URI encoding, run the following
/opt/wildfly/bin/jboss-cli.sh --connect --command='/system-property=org.apache.catalina.connector.URI_ENCODING:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/system-property=org.apache.catalina.connector.URI_ENCODING:add(value=UTF-8)'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/system-property=org.apache.catalina.connector.USE_BODY_ENCODING_FOR_QUERY_STRING:remove()'
/opt/wildfly/bin/jboss-cli.sh --connect --command='/system-property=org.apache.catalina.connector.USE_BODY_ENCODING_FOR_QUERY_STRING:add(value=true)'
sleep 5
/opt/wildfly/bin/jboss-cli.sh --connect --command=':reload'
sleep 5

echo "######################################"
echo "# Deploying SignServer.ear to Wildfly"
echo "######################################"
# Deploy SignServer 
cd /opt/signserver
bin/ant deploy