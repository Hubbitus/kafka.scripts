#!/bin/bash

# Script to list present kafka topics.
# Optionally filtered by KAFKA_TOPICS_FILTER (PERL regexp supported).
# F.e.:
# KAFKA_TOPICS_FILTER=scoring ./_kafka.list-topics.sh

source "$(dirname $0)/.shared.sh"

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

#KAFKA_HEAP_OPTS="-Xmx2048M" kafka-topics --bootstrap-server "${KAFKA_BOOTSTRAP_SERVERS}" \
podman exec $(kafka_exec_cache) kafka-topics --bootstrap-server "${KAFKA_BOOTSTRAP_SERVERS}" "${CONFLUENT_EXTRA_COMMON_OPTIONS[@]}" \
	--list 2>&1 \
		| grep -P ${KAFKA_TOPICS_FILTER-.}
