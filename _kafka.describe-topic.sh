#!/bin/bash

# Script to describe topic kafka topic (partitions, configs, policy and so on).
# F.e.:
# TOPICS=scoring ./_kafka.describe-topic.sh

source "$(dirname $0)/.shared.sh"

: ${TOPIC?"Not enough vars set: TOPIC required. E.g.: 'TOPIC=uat-scoring ./$(basename $0)'"}
: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

podman exec $(kafka_exec_cache) kafka-topics --bootstrap-server "${KAFKA_BOOTSTRAP_SERVERS}" "${CONFLUENT_EXTRA_COMMON_OPTIONS[@]}" \
	--describe --topic ${TOPIC} 2>&1
