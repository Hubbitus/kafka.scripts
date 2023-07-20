#!/usr/bin/bash

# Script to restart kafka-connect connector.
# See https://docs.confluent.io/platform/current/connect/references/restapi.html#connectors
# See also _kafka-connect.list-connectors.restart-all.sh for restart all

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}
: ${CONNECTOR?"Please ptovide CONNECTOR variable"}

curl -X POST ${KAFKA_CONNECT_HOST}/connectors/${CONNECTOR}/restart
