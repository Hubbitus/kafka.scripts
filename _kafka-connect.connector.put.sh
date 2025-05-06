#!/bin/bash

# Script to PUT (add or update) kafka-connect connector
# API detailed description: https://docs.confluent.io/platform/current/connect/references/restapi.html#put--connectors-(string-name)-config

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}
: ${CONNECTOR?"Please provide CONNECTOR variable"}
: "${CONNECTOR_CONFIG_FILE:=$(dirname $0)/_connectors/${CONNECTOR}.config.json}"

echo CONNECTOR_CONFIG_FILE=${CONNECTOR_CONFIG_FILE}

if [[ ! -e "${CONNECTOR_CONFIG_FILE}" ]]; then
	echo "Config file [_connectors/${CONNECTOR}.config.json] does not exists! Please place it there, or provide alternative path in CONNECTOR_CONFIG_FILE variable"
	exit 1
fi

http PUT ${KAFKA_CONNECT_HOST}/connectors/${CONNECTOR}/config < ${CONNECTOR_CONFIG_FILE}
