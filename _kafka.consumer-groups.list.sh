#!/usr/bin/bash

# Script to list consumer groups. Essentially sink adapters.
# Example:
# ./_kafka.consumer-groups.list.sh | grep EntityAbstract2

source $(dirname $0)/.config.sh

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

docker exec -it $(kafka_exec_cache) /usr/bin/kafka-consumer-groups --bootstrap-server ${KAFKA_BOOTSTRAP_SERVERS} \
	--list \
		"$@" 2>&1 \



#			| grep -vP "WARN The configuration '.+?' was supplied but isn't a known config" || : # Grep status have no matter - it is ok, if output empty
