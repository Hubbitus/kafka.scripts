#!/bin/bash

source "$(dirname $0)/.shared.sh"


: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}
: ${TOPIC?"Not enough vars set: TOPIC required. Example: TOPIC=topic1 $0 some-file.csv"}
: ${1?"Provide file to load into topic. Example: TOPIC=topic1 $0 some-file.csv"}

# By https://gpdb.docs.pivotal.io/streaming-server/1-3-3/kafka/load-from-kafka-example.html
podman exec -t $(kafka_exec_cache) kafka-console-producer --bootstrap-server $KAFKA_BOOTSTRAP_SERVERS \
	--topic ${TOPIC} 2>&1 < "${1}"
