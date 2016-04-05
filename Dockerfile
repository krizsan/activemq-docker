# ActiveMQ image running on Alpine Linux and Oracle Java 8 (JRE).
# The base image contains glibc, which is required for the Java Service wrapper that is used by ActiveMQ.
#
# Build image with: docker build -t ivankrizsan/activemq:latest .

FROM anapsix/alpine-java:jre8

MAINTAINER Ivan Krizsan, https://github.com/krizsan

# Software version number.
ENV VERSION_NUMBER=5.13.2 \
# Archive name prefix, unpacked archive directory prefix and final directory name.
FINAL_DIRECTORY_NAME=apache-activemq
# Software home directory.
ENV HOME_DIRECTORY=/opt/${FINAL_DIRECTORY_NAME} \
# Product download URL.
DOWNLOAD_URL=http://apache.mirrors.spacedump.net/activemq/${VERSION_NUMBER}/apache-activemq-${VERSION_NUMBER}-bin.tar.gz \
# Name of user that product will be run by.
RUN_AS_USER=activemq \
# Name of start-script that will be executed when a new container is started.
START_SCRIPT_NAME=start-activemq.sh \
# HawtIO download URL.
HAWTIO_DOWNLOAD_URL=https://oss.sonatype.org/content/repositories/public/io/hawt/hawtio-default/1.4.64/hawtio-default-1.4.64.war \
# Set this environment variable to true to set timezone on container start.
SET_CONTAINER_TIMEZONE=true \
# Default container timezone.
CONTAINER_TIMEZONE=Europe/Stockholm
# Configuration directory.
ENV CONFIGURATION_DIRECTORY=${HOME_DIRECTORY}/conf \
# Logs directory. Does not exist in the default ActiveMQ binary distribution.
LOGS_DIRECTORY=${HOME_DIRECTORY}/logs \
# Data directory. Will also contain the pid file.
DATA_DIRECTORY=${HOME_DIRECTORY}/data
# HawtIO webapp handler replacement string in ActiveMQs jetty.xml
ENV HAWTIO_WEBAPP_HANDLER_STRING='<ref bean="rewriteHandler"/> \
    <bean class="org.eclipse.jetty.webapp.WebAppContext"> \
        <property name="contextPath" value="/hawtio" /> \
        <property name="war" value="${activemq.home}/webapps/hawtio.war" /> \
        <property name="logUrlOnStart" value="true" /> \
    </bean>'

# Install NTPD for time synchronization and su-exec (instead of gosu).
RUN apk --no-cache update && \
    apk --no-cache upgrade && \
    apk --no-cache add tzdata openntpd su-exec && \
# Create the /opt directory in which software in the container is installed.
    mkdir -p /opt && \
    cd /opt && \
# Create directory used by NTPD.
    mkdir -p /var/empty && \
# Create the user and group that will be used to run the software.
    addgroup ${RUN_AS_USER} && adduser -D -G ${RUN_AS_USER} ${RUN_AS_USER} && \
# Install software.
    echo "Downloading from ${DOWNLOAD_URL}..." && \
    wget -q "${DOWNLOAD_URL}" && \
    echo "Download done." && \
    tar xvzf ${FINAL_DIRECTORY_NAME}-*.tar.gz && \
    rm -f ${FINAL_DIRECTORY_NAME}-*.tar.gz && \
    mv ${FINAL_DIRECTORY_NAME}-* ${FINAL_DIRECTORY_NAME} && \
# Create configuration, data and logs directories as needed.
    mkdir -p ${CONFIGURATION_DIRECTORY} && \
    mkdir -p ${DATA_DIRECTORY} && \
    mkdir -p ${LOGS_DIRECTORY} && \
# Set the owner of the configuration, data and logs directories in case they
# are not located in the home directory or any of its sub-directories.
    chown -R ${RUN_AS_USER}:${RUN_AS_USER} ${CONFIGURATION_DIRECTORY} && \
    chown -R ${RUN_AS_USER}:${RUN_AS_USER} ${DATA_DIRECTORY} && \
    chown -R ${RUN_AS_USER}:${RUN_AS_USER} ${LOGS_DIRECTORY} && \
# Download HawtIO to the ActiveMQ wep applications directory.
    echo "Downloading from ${HAWTIO_DOWNLOAD_URL}..." && \
    wget -q -O "${HOME_DIRECTORY}/webapps/hawtio.war" "${HAWTIO_DOWNLOAD_URL}" && \
    echo "Download done." && \
# Clean up unnecessary files and folders.
    rm -rf ${HOME_DIRECTORY}/activemq-all-*.jar \
        ${HOME_DIRECTORY}/examples \
        ${HOME_DIRECTORY}/webapps-demo \
        ${HOME_DIRECTORY}/docs && \
# Add HawtIO webapp handler to Jetty configuration in ActiveMQ.
    sed -i -e"s|<ref bean=\"rewriteHandler\"/>|${HAWTIO_WEBAPP_HANDLER_STRING}|g" ${HOME_DIRECTORY}/conf/jetty.xml && \
# Update ACTIVEMQ_OPTS in bin/env file with HawtIO security options.
    sed -i -e"s|#ACTIVEMQ_OPTS.*|ACTIVEMQ_OPTS=\"\$ACTIVEMQ_OPTS -Dhawtio.realm=activemq -Dhawtio.role=admins -Dhawtio.rolePrincipalClasses=org.apache.activemq.jaas.GroupPrincipal\"|g" ${HOME_DIRECTORY}/bin/env && \
# Update path to log files as to write them to the logs directory.
    sed -i -e"s|\${activemq.base}/data/\(.*\).log|\${activemq.base}/logs/\1.log|g" ${HOME_DIRECTORY}/conf/log4j.properties

# Copy the start script.
COPY ./start-activemq.sh ${HOME_DIRECTORY}/

# Make start script executable.
RUN chmod +x ${HOME_DIRECTORY}/${START_SCRIPT_NAME} && \
# Set the owner of all files related to the software to the user which will be used to run it.
    chown -R ${RUN_AS_USER}:${RUN_AS_USER} ${HOME_DIRECTORY}

WORKDIR ${HOME_DIRECTORY}

CMD [ "/opt/apache-activemq/start-activemq.sh" ]

# Expose ports for different types of interaction with ActiveMQ:
# Web admin application and HawtIO port.
EXPOSE 8161
# TCP communication port.
EXPOSE 61616
# AMQP port.
EXPOSE 5672
# Stomp port.
EXPOSE 61613
# MQTT port.
EXPOSE 1883
# WS port.
EXPOSE 61614

# Expose configuration, data and log directories.
VOLUME ["${CONFIGURATION_DIRECTORY}", "${DATA_DIRECTORY}", "${LOGS_DIRECTORY}"]
