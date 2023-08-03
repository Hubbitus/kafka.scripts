#!/usr/bin/bash

# Script to show kafka-connect connector status.
# API detailed description: https://docs.confluent.io/platform/current/connect/references/restapi.html#connectors
# See also _kafka-connect.list-connectors.sh
# See also _kafka-connect.list-connector.status.trace.sh

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}
: ${CONNECTOR?"Please provide CONNECTOR variable"}

http ${KAFKA_CONNECT_HOST}/connectors/${CONNECTOR}/status
