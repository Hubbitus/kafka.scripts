#!/bin/bash

# Script to delete specified in TOPIC variable Kafka topic

: ${TOPIC?"Not enough vars set: TOPIC required. Because it destructive operation we do NOT read topic name from config.sh file! Please provide it directly. F.e.: 'TOPIC=uat-scoring.match-data.Scoring ./$(basename $0)'"}

source "$(dirname $0)/.config.sh"

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

podman exec -it $(kafka_exec_cache) kafka-topics --bootstrap-server "${KAFKA_BOOTSTRAP_SERVERS}" \
		--delete --topic "${TOPIC}" 2>&1
