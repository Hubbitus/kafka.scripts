#!/usr/bin/bash

# Script to pause kafka-connect connector.
# API detailed description: https://docs.confluent.io/platform/current/connect/references/restapi.html#connectors

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}
: ${CONNECTOR?"Please provide CONNECTOR variable"}

curl -X PUT ${KAFKA_CONNECT_HOST}/connectors/${CONNECTOR}/pause
