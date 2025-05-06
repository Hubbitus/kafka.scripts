#!/bin/bash

# Script to list consumer groups. Essentially sink adapters.
# Example:
# ./_kafka.consumer-groups.list.sh | grep EntityAbstract2

source "$(dirname $0)/.shared.sh"

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

podman exec -it $(kafka_exec_cache) /usr/bin/kafka-consumer-groups --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS} "${CONFLUENT_EXTRA_COMMON_OPTIONS[@]}" \
	--list \
		"$@" 2>&1 \

#			| grep -vP "WARN The configuration '.+?' was supplied but isn't a known config" || : # Grep status have no matter - it is ok, if output empty
