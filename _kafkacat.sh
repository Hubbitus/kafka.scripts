#!/usr/bin/bash

# Script to general purpose call kafkacat from docker-container. All arguments passed directly to it
# See https://github.com/edenhill/kafkacat for kafkacat doc

source $(dirname $0)/.config.sh

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

docker exec -i $(kafkacat_exec_cache) kafkacat \
	-b ${KAFKA_BOOTSTRAP_SERVERS} \
		"$@"
