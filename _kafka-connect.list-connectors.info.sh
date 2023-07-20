#!/usr/bin/bash

# Show all kafka-connect connectors with extended connector information
# See https://docs.confluent.io/platform/current/connect/references/restapi.html#connectors

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}

./_kafka-connect.list-connectors.sh ?expand=info
