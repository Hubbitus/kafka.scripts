#!/usr/bin/bash

# Script to show kafka-connect connector status.
# See also ./_kafka-connect.list-connectors.sh

source "$(dirname $0)/.shared.sh"

: ${KAFKA_CONNECT_HOST?"Not enough vars set: KAFKA_CONNECT_HOST required"}
: ${CONNECTOR?"Please ptovide CONNECTOR variable"}

http ${KAFKA_CONNECT_HOST}/connectors/${CONNECTOR}/status
