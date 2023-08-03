#!/usr/bin/bash

# Show all kafka-connect connectors with status
# API detailed description: https://docs.confluent.io/platform/current/connect/references/restapi.html#connectors
# See also _kafka-connect.list-connector.status.sh

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}

$(dirname $0)/_kafka-connect.list-connectors.sh ?expand=status
