#!/usr/bin/bash

# Script to restart kafka-connect connector.
# API detailed description: https://docs.confluent.io/platform/current/connect/references/restapi.html#connectors
# See also _kafka-connect.connectors.restart-all.sh for restart all

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}
: ${CONNECTOR?"Please provide CONNECTOR variable"}

curl -sS -X POST "${KAFKA_CONNECT_HOST}/connectors/${CONNECTOR}/restart?includeTasks=true" | jq .
