# ActiveMQ Docker Image
Docker image with ActiveMQ and HawtIO on Alpine Linux.

In order for the time of the container to be synchronized (ntpd), it must be run with the SYS_TIME capability.
In addition you may want to add the SYS_NICE capability, in order for ntpd to be able to modify its priority.

# Volumes


# Environment
SET_CONTAINER_TIMEZONE - Set to "true" (without quotes) to set the timezone when starting a container. Default is true.<br/>
CONTAINER_TIMEZONE - Timezone to use in container. Default is Europe/Stockholm.<br/>
