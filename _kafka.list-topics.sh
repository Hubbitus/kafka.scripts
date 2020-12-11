#!/bin/bash

# Script to list present kafka topics.
# Optionally filtered by KAFKA_TOPICS_FILTER (PERL regexp supported).
# F.e.:
# KAFKA_TOPICS_FILTER=scoring ./_kafka.list-topics.sh

source "$(dirname $0)/.config.sh"

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

docker exec $(kafka_exec_cache) kafka-topics --bootstrap-server "${KAFKA_BOOTSTRAP_SERVERS}" \
	--list 2>&1 \
		| grep -P ${KAFKA_TOPICS_FILTER-.}
