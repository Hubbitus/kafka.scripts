#!/usr/bin/bash

# Script to show kafka-connect connector status and format its trace if present from JSON string to readable form
# API detailed description: https://docs.confluent.io/platform/current/connect/references/restapi.html#connectors
# See also _kafka-connect.connector.list.status.sh

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}
: ${CONNECTOR?"Please provide CONNECTOR variable"}

$(dirname $0)/_kafka-connect.connector.status.sh

echo "### Stack trace readable: ###"
$(dirname $0)/_kafka-connect.connector.status.sh \
	| jq .tasks[].trace -r
