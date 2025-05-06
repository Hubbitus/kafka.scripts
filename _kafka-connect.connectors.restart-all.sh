#!/bin/bash

# Script to easy restart ALL kafka-connect connectors.
# API detailed description: https://docs.confluent.io/platform/current/connect/references/restapi.html#connectors
# See also _kafka-connect.connector.restart.sh to restart single desired connector

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}

curl -sS ${KAFKA_CONNECT_HOST}/connectors | jq .[] -r \
	| xargs -r -I{} bash -c "CONNECTOR={} $(dirname $0)/_kafka-connect.connector.restart.sh"
