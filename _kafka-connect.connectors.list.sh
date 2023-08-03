#!/usr/bin/bash

# List all kafka-connect connectors
# API detailed description: https://docs.confluent.io/platform/current/connect/references/restapi.html#connectors

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}

http --body ${KAFKA_CONNECT_HOST}/connectors$@
