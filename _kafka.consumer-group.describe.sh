#!/bin/bash

# Script to describe consumer group (sink connector).
# You may find KAFKA_CONSUMER_GROUP value something like: ./_kafka.consumer-groups.list.sh | grep EntityAbstract2

# Example:
# KAFKA_CONSUMER_GROUP=groupname1 ./_kafka.consumer-groups.inspect.sh

source "$(dirname $0)/.shared.sh"

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}
: ${KAFKA_CONSUMER_GROUP?"Not enough vars set: KAFKA_CONSUMER_GROUP required. Please call me like: KAFKA_CONSUMER_GROUP=groupname1 $0"}

podman exec -it $(kafka_exec_cache) /usr/bin/kafka-consumer-groups --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS} "${CONFLUENT_EXTRA_COMMON_OPTIONS[@]}" \
	--describe --group ${KAFKA_CONSUMER_GROUP} \
		"$@" 2>&1
