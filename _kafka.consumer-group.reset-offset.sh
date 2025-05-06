#!/bin/bash

# Script to reset consumer group (for connector most probably).
# You may find KAFKA_CONSUMER_GROUP value something like: ./_kafka.consumer-groups.list.sh | grep EntityAbstract2

# Example:
# KAFKA_CONSUMER_GROUP=connect-gidplatform_dev.sink.GID_API_DB.masterdata TOPIC=gidplatform_dev.GID_API_DB.api.public.user ./_kafka.consumer-group.reset-offset.sh

source "$(dirname $0)/.shared.sh"

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}
: ${KAFKA_CONSUMER_GROUP?"Not enough vars set: KAFKA_CONSUMER_GROUP required. Please call me like: KAFKA_CONSUMER_GROUP=groupname1 $0"}
: ${TOPIC?"Not enough vars set: TOPIC required. Example: TOPIC=topic1 $0"}

podman exec -it $(kafka_exec_cache) /usr/bin/kafka-consumer-groups --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS} "${CONFLUENT_EXTRA_COMMON_OPTIONS[@]}" \
	--group ${KAFKA_CONSUMER_GROUP} --topic ${TOPIC} --reset-offsets --to-earliest --execute \
		"$@" 2>&1
