#!/usr/bin/bash

# Script to show kafka-connect connector config.
# API detailed description: https://docs.confluent.io/platform/current/connect/references/restapi.html#get--connectors-(string-name)-config

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}
: ${CONNECTOR?"Please provide CONNECTOR variable"}

http ${KAFKA_CONNECT_HOST}/connectors/${CONNECTOR}/config
