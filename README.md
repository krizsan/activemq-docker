# ActiveMQ Docker Image
Docker image with ActiveMQ and HawtIO on Alpine Linux.

In order for the time of the container to be synchronized (ntpd), it must be run with the SYS_TIME capability.
In addition you may want to add the SYS_NICE capability, in order for ntpd to be able to modify its priority.

# Volumes
* /opt/apache-activemq/conf - Directory holding ActiveMQ configuration files.
* /opt/apache-activemq/data - Data directory. Will contain KahaDB data. Will not contain logs.
* /opt/apache-activemq/logs - Logs directory. In the default configuration, this directory will contain the ActiveMQ and audit log files.

# Ports

* 8161    - Web admin application and HawtIO port.
* 61616   - TCP communication port.
* 5672    - AMQP port.
* 61613   - Stomp port.
* 1883    - MQTT port.
* 61614   - WS port.

# Environment
* SET_CONTAINER_TIMEZONE  - Set to "true" (without quotes) to set the timezone when starting a container. Default is true.
* CONTAINER_TIMEZONE      - Timezone to use in container. Default is Europe/Stockholm.
