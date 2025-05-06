#!/bin/bash

# Script to DELETE kafka-connect connector
# API detailed description: https://docs.confluent.io/platform/current/connect/references/restapi.html#put--connectors-(string-name)-config

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}
: ${CONNECTOR?"Please provide CONNECTOR variable"}

http DELETE ${KAFKA_CONNECT_HOST}/connectors/${CONNECTOR}
