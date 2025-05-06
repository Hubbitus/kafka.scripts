#!/bin/bash

# Show all kafka-connect connectors with extended connector information
# API detailed description: https://docs.confluent.io/platform/current/connect/references/restapi.html#connectors
# See https://docs.confluent.io/platform/current/connect/references/restapi.html#connectors

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}

$(dirname $0)/_kafka-connect.connectors.list.sh ?expand=info
