#!/usr/bin/bash

# Script to general purpose call kafkacat from docker-container. All arguments passed directly to it

source $(dirname $0)/.config.sh

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

kafkacat_exec_cache

docker exec -i kafkacat-exec-cache kafkacat \
	-b ${KAFKA_BOOTSTRAP_SERVERS} -X security.protocol=SSL \
		"$@"
