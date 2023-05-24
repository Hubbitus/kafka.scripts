#!/usr/bin/bash

# Script to list present kafka topics.
# Unlike _kafka.list-topics.sh will show also partitions

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}

curl -sS ${KAFKA_CONNECT_HOST}/connectors | jq .[] -r \
	| xargs -r -I{} curl -X POST ${KAFKA_CONNECT_HOST}/connectors/{}/restart
