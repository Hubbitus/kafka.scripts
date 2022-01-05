#!/bin/bash

source "$(dirname $0)/.config.sh"


: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

podman exec -it $(kafka_exec_cache) kafka-acls --bootstrap-server $KAFKA_BOOTSTRAP_SERVERS \
	--list 2>&1 \
		"$@"
