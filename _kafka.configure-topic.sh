#!/bin/bash

source "$(dirname $0)/.config.sh"

: ${TOPIC?"Not enough vars set: TOPIC required. E.g.: 'TOPIC=uat-scoring CONFIG="cleanup.policy=compact" ./$(basename $0)'"}
: ${CONFIG?"Not enough vars set: CONFIG required. E.g.: 'TOPIC=uat-scoring CONFIG="retention.ms=10000" ./$(basename $0)'"}
: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

docker exec $(kafka_exec_cache) kafka-configs --bootstrap-server "${KAFKA_BOOTSTRAP_SERVERS}" \
	--alter --entity-type topics --entity-name ${TOPIC} \
	--add-config "${CONFIG}" 2>&1
