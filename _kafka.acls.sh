#!/bin/bash

source "$(dirname $0)/.shared.sh"

: ${KAFKA_BOOTSTRAP_SERVERS?"Not enough vars set: KAFKA_BOOTSTRAP_SERVERS required"}

podman exec -it $(kafka_exec_cache) kafka-acls --bootstrap-server $KAFKA_BOOTSTRAP_SERVERS 2>&1 \
	"$@"
