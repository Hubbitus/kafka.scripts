#!/usr/bin/bash

# Script to REinstall connector: Get congig, delete, put with same config
# API detailed description: https://docs.confluent.io/platform/current/connect/references/restapi.html#put--connectors-(string-name)-config

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}
: ${CONNECTOR?"Please provide CONNECTOR variable"}

: "${CONNECTOR_CONFIG_FILE:=$(dirname $0)/_connectors/_${CONNECTOR}.config.json}"

echo "CONNECTOR_CONFIG_FILE=${CONNECTOR_CONFIG_FILE}"

echo "1) DUMP configuration into ${CONNECTOR_CONFIG_FILE}"
. ./_kafka-connect.connector.config.sh | jq . > "${CONNECTOR_CONFIG_FILE}"
echo "2) Delete connector [$CONNECTOR]"
. ./_kafka-connect.connector.delete.sh
echo "3) Create (put) connector [$CONNECTOR]"
. ./_kafka-connect.connector.put.sh
echo "3.1) Wait 3 seconds to start, then status will be printed (you may safely inturrept it at this point)"
sleep 3
# To check:
echo "4) Status of the connector [$CONNECTOR]"
. ./_kafka-connect.connector.status.trace.sh
